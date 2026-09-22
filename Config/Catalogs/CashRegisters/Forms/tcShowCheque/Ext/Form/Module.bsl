

#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Property("SelDocument", SelDocument) Or Not ValueIsFilled(SelDocument) Then
		pCancel = True;
		Return;
	EndIf;
	
	vChequeAttributes = cmGetChequeAttributes(SelDocument);
	If vChequeAttributes = Undefined Or IsBlankString(vChequeAttributes.ChequeFiscalNumber) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Cheque was not processed'; de = 'Kassenbon wurde nicht bearbeitet'; ru = 'Чек не пробит'"));
		pCancel = True;
		Return;
	EndIf;
	
	vChequeFiscalNumber = TrimAll(vChequeAttributes.ChequeFiscalNumber);
	vFiscalStorageFactoryNumber = TrimAll(vChequeAttributes.FiscalStorageFactoryNumber);
	vCashDayChequeNumber = TrimAll(vChequeAttributes.CashDayChequeNumber);
	vChequeSequenceNumber = TrimAll(vChequeAttributes.ChequeSequenceNumber);
	
	HTML = TrimAll(SelDocument.CashRegister.ChequeVerificationInternetAddress);
	HTML = StrReplace(HTML, "%ChequeFiscalNumber%", vChequeFiscalNumber);
	HTML = StrReplace(HTML, "%FiscalStorageFactoryNumber%", vFiscalStorageFactoryNumber);
	HTML = StrReplace(HTML, "%CashDayChequeNumber%", vCashDayChequeNumber);
	HTML = StrReplace(HTML, "%ChequeSequenceNumber%", vChequeSequenceNumber);
	HTML = StrReplace(HTML, "%ChequeAmount%", Format(vChequeAttributes.Sum, "NFD=2; NDS=.; NG="));
EndProcedure // OnCreateAtServer

#EndRegion
