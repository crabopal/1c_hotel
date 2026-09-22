
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes from parameters
	If Parameters.Property("Charge") Then
		Charge = Parameters.Charge;
	EndIf;
	If Not ValueIsFilled(Charge) Then
		pCancel = True;
		Return;
	EndIf;
	If Parameters.Property("Folio") Then
		Folio = Parameters.Folio;
	EndIf;
	QuantityBeforeSplit = Charge.Quantity;
	AmountBeforeSplit = Charge.Sum - Charge.DiscountSum;
	AmountAfterSplit = AmountBeforeSplit;
	CorrectionType = 1;
	CorrectionTypeOnChangeAtServer();
	CalculateSplitAmounts();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CorrectionTypeOnChange(pItem)
	CorrectionTypeOnChangeAtServer();
EndProcedure // CorrectionTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PercentageOnChange(pItem)
	CalculateSplitAmounts();
EndProcedure // PercentageOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SplittedAmountOnChange(pItem)
	CalculateSplitAmounts();
EndProcedure // SplittedAmountOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ApplySplit(pCommand)
	If SplittedAmount = 0 Then
		ShowMessageBox(, NStr("en='Splitted amount is zero!'; ru='Сумма разделения равна нулю!'; de='Aufteilungsumme ist Null!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Folio) Then
		ShowMessageBox(, NStr("en='Folio is empty!'; ru='Не выбран лицевой счет!'; de='Folio nicht angegeben!'"));
		Return;
	ElsIf tcOnServer.cmGetAttributeByRef(Folio, "IsClosed") Then
		ShowMessageBox(, NStr("en='Folio is closed!'; ru='Лицевой счет закрыт!'; de='Folio ist geschlossen!'"));
	EndIf;
	// Do processing
	ApplySplitAtServer();
	// Notify changes
	Notify("Subsystem.Accounts.Changed", Folio, ThisForm);
	// Close form
	ThisForm.Close();
EndProcedure // ApplySplit

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ApplySplitAtServer()
	BeginTransaction(DataLockControlMode.Managed);

	// Create new charge
	vChargeObj = Charge.Copy();
	vChargeObj.Date = Charge.Date;
	
	vChargeObj.IsAdditional = True;
	
	vChargeObj.CorrectedCharge = Charge;
	vChargeObj.IsCorrection = True;
	vChargeObj.CorrectionDate = Charge.Date;
	vChargeObj.ChargeCorrectionType = Enums.ChargeCorrectionTypes.Correction;
	
	vChargeObj.ChargeTransfer = Undefined;
	vChargeObj.RoomRevenueCharge = Undefined;
	vChargeObj.IsMergedToRoomRevenue = False;
	
	vChargeObj.Remarks = TrimAll(Remarks);
	
	vChargeObj.AgentCommission = 0;
	vChargeObj.VATCommissionSum = 0;
	vChargeObj.AgentCommissionType = Undefined;
	vChargeObj.AgentCommissionServiceGroup = Undefined;
	vChargeObj.CommissionSum = 0;
	
	vChargeObj.DiscountSum = 0;
	vChargeObj.VATDiscountSum = 0;
	vChargeObj.Discount = 0;
	vChargeObj.DiscountCard = Undefined;
	vChargeObj.DiscountType = Undefined;
	vChargeObj.DiscountServiceGroup = Undefined;
	vChargeObj.DiscountConfirmationText = Undefined;
	
	vChargeObj.RoomsRented = 0;
	vChargeObj.BedsRented = 0;
	vChargeObj.AdditionalBedsRented = 0;
	vChargeObj.GuestDays = 0;
	vChargeObj.GuestsCheckedIn = 0;
	
	vChargeObj.Sum = Round(SplittedAmount, 2);
	vChargeObj.Price = 0;
	vChargeObj.Quantity = 0;
	vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
	
	vChargeObj.RateSum = 0;
	vChargeObj.RateDiscountSum = 0;
	vChargeObj.RateCommissionSum = 0;
	
	vInitQuantity = Charge.Quantity;
	vOldQuantity = vInitQuantity;
	If SplittedQuantity <> 0 And ?(SplittedQuantity < 0, -SplittedQuantity, SplittedQuantity) < ?(Charge.Quantity < 0, -Charge.Quantity, Charge.Quantity) Then
		vChargeObj.Quantity = SplittedQuantity;
		vOldQuantity = ?(Charge.Quantity < 0, -Charge.Quantity, Charge.Quantity) - ?(SplittedQuantity < 0, -SplittedQuantity, SplittedQuantity);
		vChargeObj.Price = Round(?(vChargeObj.Sum < 0, -vChargeObj.Sum, vChargeObj.Sum) / ?(vChargeObj.Quantity < 0, -vChargeObj.Quantity, vChargeObj.Quantity), 2);
	EndIf;
	
	vK2 = ?((Charge.Sum - Charge.DiscountSum) <> 0, vChargeObj.Sum/(Charge.Sum - Charge.DiscountSum), 0);
	
	vChargeObj.CommissionSum = ?(vChargeObj.Sum < 0, -1, 1) * Round(Charge.CommissionSum * vK2, 2);
	vChargeObj.VATCommissionSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.CommissionSum, vChargeObj.Date);
	
	vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
	vChargeObj.Write(DocumentWriteMode.Posting);

	// Update old charge
	vOldChargeObj = Charge.GetObject();
	
	vOldChargeObj.Sum = Round(vOldChargeObj.Sum - SplittedAmount, 2);
	vOldChargeObj.Price = ?(vOldChargeObj.Quantity <> 0, Round(vOldChargeObj.Sum / vOldChargeObj.Quantity, 2), vOldChargeObj.Sum);
	vOldChargeObj.VATSum = cmCalculateVATSum(vOldChargeObj.VATRate, vOldChargeObj.Sum, vOldChargeObj.Date);
	
	vK2 = ?((Charge.Sum - Charge.DiscountSum) <> 0, vOldChargeObj.Sum/(Charge.Sum - Charge.DiscountSum), 0);
	
	vOldChargeObj.CommissionSum = ?(vOldChargeObj.Sum < 0, -1, 1) * Round(Charge.CommissionSum * vK2, 2);
	vOldChargeObj.VATCommissionSum = cmCalculateVATSum(vOldChargeObj.VATRate, vOldChargeObj.CommissionSum, vOldChargeObj.Date);

	If (vOldChargeObj.RateSum - vOldChargeObj.RateDiscountSum) > SplittedAmount Then
		vOldChargeObj.RateSum = Round(vOldChargeObj.RateSum - SplittedAmount, 2);
		vOldChargeObj.RateCommissionSum = ?(vOldChargeObj.RateSum < 0, -1, 1) * Round(Charge.RateCommissionSum * vK2, 2);
	Else
		vOldChargeObj.RateSum = 0;
		vOldChargeObj.RateDiscountSum = 0;
		vOldChargeObj.RateCommissionSum = 0;
	Endif;
	
	If vOldQuantity <> 0 And ?(vOldQuantity < 0, -vOldQuantity, vOldQuantity) <> ?(vInitQuantity < 0, -vInitQuantity, vInitQuantity) Then
		vOldChargeObj.Quantity = ?(vInitQuantity < 0, -vOldQuantity, vOldQuantity);
		vOldChargeObj.Price = Round(?(vOldChargeObj.Sum < 0, -vOldChargeObj.Sum, vOldChargeObj.Sum) / ?(vOldChargeObj.Quantity < 0, -vOldChargeObj.Quantity, vOldChargeObj.Quantity), 2);
	EndIf;
	
	vOldChargeObj.CorrectedCharge = Charge;
	
	vOldChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
	vOldChargeObj.Write(DocumentWriteMode.Posting);
	
	CommitTransaction();
EndProcedure // ApplyCorrectionAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CorrectionTypeOnChangeAtServer()
	CalculateSplitAmounts();
	If CorrectionType = 0 Then
		Items.SplittedPercentage.Visible = True;
	Else
		SplittedPercentage = 0;
		Items.SplittedPercentage.Visible = False;
	EndIf;
EndProcedure // CorrectionTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CalculateSplitAmounts()
	If CorrectionType = 0 Then
		SplittedAmount = Round(AmountBeforeSplit * (SplittedPercentage / 100), 2);
	EndIf;
	AmountAfterSplit = AmountBeforeSplit - SplittedAmount;
EndProcedure // CalculateSplitAmounts

#EndRegion

