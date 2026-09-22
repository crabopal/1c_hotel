
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;	
	EndIf;
	GetGroupTotals();
	GroupProformaInvoices.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	GroupProformaInvoices.Parameters.SetParameterValue("BeginOfPeriod", '00010101');
	GroupProformaInvoices.Parameters.SetParameterValue("EndOfPeriod", '39991231235959');
EndProcedure //  OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.GroupProformaInvoices.Refresh();
EndProcedure //  OnOpen

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure GetGroupTotals()
	vGuestGroupObj = SelGuestGroup.GetObject();
	
	// Group is preliminary status
	vIsPreliminary = vGuestGroupObj.pmIsPreliminary();
	
	vHotel = vGuestGroupObj.Owner;
	
	vTotals = vGuestGroupObj.pmGetRoomInventoryTotals();
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals[0];
		TotalGuestsReservedByGroup = vTotalsRow.GuestsExpected;
		TotalRoomReservedByGroup = vTotalsRow.RoomsExpected;
		TotalGuestsCheckInByGroup = vTotalsRow.GuestsCheckedIn;
		TotalRoomCheckInByGroup = vTotalsRow.RoomsCheckedIn;
	EndIf;
	
	// Sales
	vGuestGroupBalance = 0;
	vGuestGroupSales = 0;
	vSalesInBaseCurrency = 0;
	vSales = vGuestGroupObj.pmGetSalesTotals();
	vSales.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales");
	For Each vSalesRow In vSales Do
		If Not vIsPreliminary Then
			TotalGroupSales = TotalGroupSales + ?(IsBlankString(TotalGroupSales), "", ", ") + cmFormatSum(vSalesRow.Sales + vSalesRow.SalesForecast, vSalesRow.Currency);
			vSalesInBaseCurrency = cmConvertCurrencies(vSalesRow.Sales + vSalesRow.SalesForecast, vSalesRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
			vGuestGroupBalance = vGuestGroupBalance + vSalesInBaseCurrency;
			vGuestGroupSales = vGuestGroupSales + vSalesInBaseCurrency;
		Else
			TotalGroupSales = TotalGroupSales + ?(IsBlankString(TotalGroupSales), "", ", ") + cmFormatSum(vSalesRow.Sales + vSalesRow.ExpectedSales, vSalesRow.Currency);
			vSalesInBaseCurrency = cmConvertCurrencies(vSalesRow.Sales + vSalesRow.ExpectedSales, vSalesRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
			vGuestGroupBalance = vGuestGroupBalance + vSalesInBaseCurrency;
			vGuestGroupSales = vGuestGroupSales + vSalesInBaseCurrency;
		EndIf;
	EndDo;
	
	// Payments
	vPayments = vGuestGroupObj.pmGetPaymentsTotals();
	vPayments.GroupBy("Currency", "Sum");
	For Each vPaymentsRow In vPayments Do
		TotalGroupPayments = TotalGroupPayments + ?(IsBlankString(TotalGroupPayments), "", ", ") + cmFormatSum(vPaymentsRow.Sum, vPaymentsRow.Currency);
		vGuestGroupBalance = vGuestGroupBalance - cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
	EndDo;
	
	// Balance
	TotalGroupBalance = cmFormatSum(vGuestGroupBalance, vHotel.BaseCurrency);
	
	// Get group resources
	TGroupResources = vGuestGroupObj.pmGetResourceCodes();
EndProcedure //  GetGroupTotals

#EndRegion