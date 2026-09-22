
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes from parameters
	If Parameters.Property("Charges") Then
		Charges.LoadValues(Parameters.Charges.UnloadValues());
	EndIf;
	If Charges.Count() > 0 Then
		For Each vChargesItem In Charges Do
			vChargeRef = vChargesItem.Value;
			If ValueIsFilled(vChargeRef) And ValueIsFilled(vChargeRef.Service) Then
				If ValueIsFilled(vChargeRef.Service.CorrectionService) Then
					CorrectionService = vChargeRef.Service.CorrectionService;
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If Parameters.Property("Folio") Then
		Folio = Parameters.Folio;
	EndIf;
	If Parameters.Property("Amount") Then
		AmountBeforeCorrection = Parameters.Amount;
	EndIf;
	AmountAfterCorrection = AmountBeforeCorrection;
	CalculateCorrectionAmounts();
	SetDiscountTitle();
	ChargeCorrectionType = Enums.ChargeCorrectionTypes.Correction;
	SetChargeCorrectionTypeAppearance();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CorrectionSignOnChange(pItem)
	CalculateCorrectionAmounts();
	SetDiscountTitle();
EndProcedure // CorrectionSignOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure CorrectionTypeOnChange(pItem)
	CalculateCorrectionAmounts();
	SetDiscountTitle();
EndProcedure // CorrectionTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	CalculateCorrectionAmounts();
EndProcedure // DiscountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AmountBeforeCorrectionOnChange(pItem)
	CalculateCorrectionAmounts();
EndProcedure // AmountBeforeCorrectionOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetChargeCorrectionTypeAppearance()
	vAccountsCount = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(ChartOfAccountsFO.Ref) AS AccCount
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO AS ChartOfAccountsFO
	|WHERE
	|	(ChartOfAccountsFO.ComplimentaryIncomeAccount <> &qEmptyAccount
	|			OR ChartOfAccountsFO.DiscountIncomeAccount <> &qEmptyAccount
	|			OR ChartOfAccountsFO.ComplimentaryExpensesAccount <> &qEmptyAccount
	|			OR ChartOfAccountsFO.DiscountExpensesAccount <> &qEmptyAccount)
	|	AND NOT ChartOfAccountsFO.DeletionMark
	|	AND (ChartOfAccountsFO.Hotel = &qHotel
	|			OR ChartOfAccountsFO.Hotel = &qEmptyHotel)";
	vQry.SetParameter("qEmptyAccount", ChartsOfAccounts.ChartOfAccountsFO.EmptyRef());
	vQry.SetParameter("qHotel", ?(ValueIsFilled(Folio), Folio.Hotel, SessionParameters.CurrentHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vAccountsCountRows = vQry.Execute().Unload();
	If vAccountsCountRows.Count() > 0 Then
		vAccountsCountRow = vAccountsCountRows.Get(0);
		If vAccountsCountRow.AccCount <> Null And cmIsNumber(vAccountsCountRow.AccCount) Then
			vAccountsCount = vAccountsCountRow.AccCount;
		EndIf;
	EndIf;
	If vAccountsCount = 0 Then
		Items.ChargeCorrectionType.Visible = False;
	Else
		Items.ChargeCorrectionType.Visible = True;
	EndIf;
EndProcedure // SetChargeCorrectionTypeAppearance

// --------------------------------------------------------------------------------
&AtServer
Procedure ApplyCorrectionAtServer()
	If Charges.Count() = 0 Then
		Return;
	EndIf;
	
	vNumberOfCharges = Charges.Count();
	vNumberOfCharges = ?(vNumberOfCharges = 0, 1, vNumberOfCharges);
	
	vAvgAmount = Round(AmountBeforeCorrection/vNumberOfCharges, 2);
	
	BeginTransaction(DataLockControlMode.Managed);
	
	vRestOfCorrectionAmount = CorrectionAmount;
	For Each vChargesItem In Charges Do
		vBasisCharge = vChargesItem.Value;
		
		vDesiredChargeDate = '00010101';
		vChargeObj = vBasisCharge.Copy();
		vChargeObj.pmFillAuthorAndDate();
		If ValueIsFilled(vChargeObj.Hotel) And ValueIsFilled(vChargeObj.Hotel.AccountingDate) And 
		   BegOfDay(vChargeObj.Date) > BegOfDay(vChargeObj.Hotel.AccountingDate) Then
			vDesiredChargeDate = EndOfDay(vChargeObj.Hotel.AccountingDate);
			vChargeObj.Date = vDesiredChargeDate;
			vChargeObj.SetTime(AutoTimeMode.DontUse);
		EndIf;
		If Year(vBasisCharge.Date) <> Year(vChargeObj.Date) Then
			vChargeObj.SetNewNumber();
		EndIf;
		
		vChargeObj.IsAdditional = True;
		
		If ValueIsFilled(CorrectionService) Then
			vChargeObj.Service = CorrectionService;
		EndIf;
		If ValueIsFilled(vBasisCharge.ServiceDate) Then
			vChargeObj.ServiceDate = vBasisCharge.ServiceDate;
		Else
			vChargeObj.ServiceDate = vBasisCharge.Date;
		EndIf;
		
		vChargeObj.CorrectedCharge = vBasisCharge;
		vChargeObj.IsCorrection = True;
		vChargeObj.CorrectionDate = vBasisCharge.Date;
		vChargeObj.ChargeCorrectionType = ChargeCorrectionType;
		vChargeObj.RoomRevenueCharge = Undefined;
		vChargeObj.IsMergedToRoomRevenue = False;
		
		vChargeObj.ChargeTransfer = Undefined;
		
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
		
		vChargeObj.RateSum = 0;
		vChargeObj.RateDiscountSum = 0;
		vChargeObj.RateCommissionSum = 0;
		
		vK1 = (vBasisCharge.Sum - vBasisCharge.DiscountSum)/?(vAvgAmount = 0, 1, vAvgAmount);
		If Charges.IndexOf(vChargesItem) = (Charges.Count() - 1) Then
			vChargeObj.Sum = vRestOfCorrectionAmount;
		Else
			vChargeObj.Sum = Round(CorrectionAmount/vNumberOfCharges*vK1, 2);
		EndIf;
		vRestOfCorrectionAmount = vRestOfCorrectionAmount - vChargeObj.Sum;
		vChargeObj.Price = 0;
		vChargeObj.Quantity = 0;
		vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
		
		vK2 = vChargeObj.Sum/(vBasisCharge.Sum - vBasisCharge.DiscountSum);
		vChargeObj.CommissionSum = ?(vChargeObj.Sum < 0, -1, 1) * Round(vBasisCharge.CommissionSum * vK2, 2);
		vChargeObj.VATCommissionSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.CommissionSum, vChargeObj.Date);
		
		vChargeObj.Write(DocumentWriteMode.Posting);
		
		If ValueIsFilled(vDesiredChargeDate) And vChargeObj.Date <> vDesiredChargeDate Then
			vChargeObj.Date = vDesiredChargeDate;
			vChargeObj.Write(DocumentWriteMode.Posting);
		EndIf;			
	EndDo;
	
	CommitTransaction();
EndProcedure // ApplyCorrectionAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ApplyCorrection(pCommand)
	If CorrectionAmount = 0 Then
		ShowMessageBox(, NStr("en='Correction amount is zero!'; ru='Сумма коррекции равна нулю!'; de='Korrektursumme ist Null!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Folio) Then
		ShowMessageBox(, NStr("en='Folio is empty!'; ru='Не выбран лицевой счет!'; de='Folio nicht angegeben!'"));
		Return;
	EndIf;
	// Do processing
	ApplyCorrectionAtServer();
	// Notify changes
	Notify("Subsystem.Accounts.Changed", Folio, ThisForm);
	// Close form
	ThisForm.Close();
EndProcedure // ApplyCorrection

// --------------------------------------------------------------------------------
&AtServer
Procedure SetDiscountTitle()
	If CorrectionSign = 0 Then
		If CorrectionType = 0 Then
			Items.Discount.Title = NStr("en='Discount %'; ru='Скидка %'; de='Rabatt %'");
		Else
			Items.Discount.Title = NStr("en='Discount amount'; ru='Сумма скидки'; de='Rabatt Summe'");
		EndIf;
	Else
		If CorrectionType = 0 Then
			Items.Discount.Title = NStr("en='Extra %'; ru='Наценка %'; de='Aufpreis %'");
		Else
			Items.Discount.Title = NStr("en='Extra amount'; ru='Сумма наценки'; de='Aufpreis Summe'");
		EndIf;
	EndIf;
EndProcedure // SetDiscountTitle

// --------------------------------------------------------------------------------
&AtServer
Procedure CalculateCorrectionAmounts()
	If CorrectionType = 0 Then
		CorrectionAmount = Round(?(CorrectionSign = 0, -1, 1) * AmountBeforeCorrection * (Discount / 100), 2);
	Else
		CorrectionAmount = ?(CorrectionSign = 0, -1, 1) * Discount;
	EndIf;
	AmountAfterCorrection = AmountBeforeCorrection + CorrectionAmount;
EndProcedure // CalculateCorrectionAmount

#EndRegion
