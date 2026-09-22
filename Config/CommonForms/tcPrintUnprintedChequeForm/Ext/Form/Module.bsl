#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("IsCloseOfCashRegisterDay") Then
		IsCloseOfCashRegisterDay = Parameters.IsCloseOfCashRegisterDay;
	Else
		IsCloseOfCashRegisterDay = False;	
	EndIf;
	If Parameters.Property("SelDateFrom") Then
		SelDateFrom = Parameters.SelDateFrom; 	
	EndIf;
	If Parameters.Property("SelDateTo") Then
		SelDateTo = Parameters.SelDateTo;	
	EndIf;
	Items.CashRegisters.Visible = Not IsCloseOfCashRegisterDay;
	Items.QueryInfo.Visible = IsCloseOfCashRegisterDay;
	Items.ActionCancel.Visible = IsCloseOfCashRegisterDay;
	If Parameters.Property("SelCashRegister") And ValueIsFilled(Parameters.SelCashRegister) Then
		SelCashRegister = Parameters.SelCashRegister;
	Else
		Items.CashRegisters.Visible = True;	
	EndIf;
	vIsAdministrator = IsInRole("Administrator"); 
	Items.SelDateFrom.Visible = vIsAdministrator;
	Items.SelDateTo.Visible = vIsAdministrator;
	FillListPaymentsUnprintedFromCashRegister();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegistersOnChange(pItem)
	FillListPaymentsUnprintedFromCashRegister();
EndProcedure // CashRegistersOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentsUnprintedFromCashRegisterListBeforeEditEnd(pItem, pNewRow, pCancelEdit, pCancel)
	vCurData = Items.PaymentsUnprintedFromCashRegisterList.CurrentData;
	If vCurData.Status = 20 Then
		pCancel = True;
		vCurData.IsUse = False;	
	EndIf;
EndProcedure // PaymentsUnprintedFromCashRegisterListBeforeEditEnd

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAll(pCommand)
	For Each vItem In PaymentsUnprintedFromCashRegisterList Do
		If vItem.Status = 18 Then 
			vItem.IsUse = True;
		EndIf;
	EndDo;
EndProcedure // SelectAll

// -----------------------------------------------------------------------------
&AtClient
Procedure UnselectAll(pCommand)
	For Each vItem In PaymentsUnprintedFromCashRegisterList Do 
		vItem.IsUse = False;
	EndDo;
EndProcedure // UnselectAll

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	FillListPaymentsUnprintedFromCashRegister();
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionCancel(pCommand)
	Items.GroupQuery.Visible = False;
	Items.QueryInfo.Visible = False;
	Items.FormCloseOfShift.Visible = True;
EndProcedure // ActionCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	vMessage = "";
	vPaymentsUnprintedFromCashRegisterArr = PaymentsUnprintedFromCashRegisterList.FindRows(New Structure("IsUse, Status", True, 18));
	vErrorCashRegistersArr = New Array();
	For Each vDocument In vPaymentsUnprintedFromCashRegisterArr Do
		If vErrorCashRegistersArr.Find(vDocument.CashRegisters) = Undefined Then 
			If Not IsReadyToPrintCheque(vMessage, vDocument.CashRegisters) Then
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, tcOnServer.cmNStrAtServer(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vMessage));
				vErrorCashRegistersArr.Add(vDocument.CashRegisters);
				Continue;
			EndIf;
		Else
			Continue;
		EndIf;
		If Not StartPrintCheque(vMessage, vDocument.CashRegisters,vDocument.Document) Then
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vMessage));
			Break;
		Else
			vDocument.IsUse = False;
			vDocument.Status = 20;
			vDocument.StatusPresentation = NStr("en = 'Printed'; de = 'Gedruckt'; ru = 'Распечатан'");
		EndIf;
		tcOnServer.Wait(2);
	EndDo;
	vPaymentsUnprintedFromCashRegisterArr = PaymentsUnprintedFromCashRegisterList.FindRows(New Structure("IsUse, Status", True, 18)); 
	If IsCloseOfCashRegisterDay And vPaymentsUnprintedFromCashRegisterArr.Count() = 0 Then 
		Items.GroupQuery.Visible = False;
		Items.QueryInfo.Visible = False;
		Items.FormCloseOfShift.Visible = True;
	Else
		ShowMessageBox(,NStr("en = 'Failed to print cheque:'; de = 'Kassenbon konnten nicht gedruckt werden:'; ru = 'Не удалось распечатать чеки:'") + TrimAll(vPaymentsUnprintedFromCashRegisterArr.Count()));	
	EndIf;
EndProcedure // ActionExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseOfShift(pCommand)
	Close(True);
EndProcedure // CloseOfShift

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListPaymentsUnprintedFromCashRegister()
	PaymentsUnprintedFromCashRegisterList.Clear();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	CashRegisters.Ref AS Ref
	|INTO CashRegistersList
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CASE
	|			WHEN &qCashRegister <> VALUE(Catalog.CashRegisters.EmptyRef)
	|				THEN CashRegisters.Ref = &qCashRegister
	|			ELSE TRUE
	|		END
	|	AND CashRegisters.IsControlledByProgram
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentsList.Ref AS Document,
	|	PaymentsList.CashRegister AS CashRegisters,
	|	FALSE AS IsUse,
	|	18 AS Status,
	|	&qStatusPresentation AS StatusPresentation,
	|	PaymentsList.Date AS Date,
	|	ChequeAttributes.Remarks AS Remarks
	|FROM
	|	Document.Payment AS PaymentsList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON PaymentsList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON PaymentsList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON PaymentsList.Ref = ChequeAttributes.Payment
	|WHERE
	|	PaymentsList.Posted
	|	AND CASE
	|			WHEN &qDateFrom <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN PaymentsList.Date >= &qDateFrom
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qDateTo <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN PaymentsList.Date <= &qDateTo
	|			ELSE TRUE
	|		END
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")
	|
	|UNION ALL
	|
	|SELECT
	|	ReturnList.Ref,
	|	ReturnList.CashRegister,
	|	FALSE,
	|	18,
	|	&qStatusPresentation,
	|	ReturnList.Date,
	|	ChequeAttributes.Remarks
	|FROM
	|	Document.Return AS ReturnList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON ReturnList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON ReturnList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON ReturnList.Ref = ChequeAttributes.Payment
	|WHERE
	|	ReturnList.Posted
	|	AND CASE
	|			WHEN &qDateFrom <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN ReturnList.Date >= &qDateFrom
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qDateTo <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN ReturnList.Date <= &qDateTo
	|			ELSE TRUE
	|		END
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerPaymentList.Ref,
	|	CustomerPaymentList.CashRegister,
	|	FALSE,
	|	18,
	|	&qStatusPresentation,
	|	CustomerPaymentList.Date,
	|	ChequeAttributes.Remarks
	|FROM
	|	Document.CustomerPayment AS CustomerPaymentList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON CustomerPaymentList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON CustomerPaymentList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON CustomerPaymentList.Ref = ChequeAttributes.Payment
	|WHERE
	|	CustomerPaymentList.Posted
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")";
	vQuery.SetParameter("qCashRegister", SelCashRegister);
	vQuery.SetParameter("qDateFrom", SelDateFrom);
	vQuery.SetParameter("qDateTo", SelDateTo);
	vQuery.SetParameter("qStatusPresentation", NStr("en = 'Not printed'; de = 'Nicht gedruckt'; ru = 'Не распечатан'"));
	vPayments = vQuery.Execute().Unload();
	ValueToFormAttribute(vPayments, "PaymentsUnprintedFromCashRegisterList");
	PaymentsUnprintedFromCashRegisterList.Sort("IsUse, Date");
EndProcedure // FillListPaymentsUnprintedFromCashRegister

// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToPrintCheque(rMessage, pCashRegister)
	rMessage = "";
	If Not ValueIsFilled(pCashRegister) Then
		Return False;
	EndIf;
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If Not vDriver = Undefined Then
		Return vDriver.pmIsReadyToPrint(rMessage, , pCashRegister);
	Else
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction // IsReadyToPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Function StartPrintCheque(rMessage, pCashRegisters, pDocument)
	vDriver = tcOnClient.cmGetModulTO(pCashRegisters);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, pCashRegisters);
		If TypeOf(pDocument) = Type("DocumentRef.Payment") Then
			FillObjectByDocument(pDocument, "Payment");
			Return vDriver.pmPrintCheque(SelObjPayment.Sum, SelObjPayment.VATSum, SelObjPayment, pDocument, rMessage, vPasswordKKM, , , , , , , SelObjPayment.SendPayerContactsToOFD, SelObjPayment.EmailToSendToOFD, SelObjPayment.PhoneToSendToOFD);
		ElsIf TypeOf(pDocument) = Type("DocumentRef.CustomerPayment") Then
			FillObjectByDocument(pDocument, "CustomerPayment");
			Return vDriver.pmPrintCustomerCheque(SelObjCustomerPayment.Sum, SelObjCustomerPayment.VATSum, SelObjCustomerPayment, pDocument, rMessage, vPasswordKKM, , , , , ,  SelObjCustomerPayment.SendPayerContactsToOFD, SelObjCustomerPayment.EmailToSendToOFD, SelObjCustomerPayment.PhoneToSendToOFD);
		Else
			FillObjectByDocument(pDocument, "Return");
			Return vDriver.pmPrintCheque(-SelObjReturn.Sum, -SelObjReturn.VATSum, SelObjReturn, pDocument, rMessage, vPasswordKKM, , , , , , , SelObjReturn.SendPayerContactsToOFD, SelObjReturn.EmailToSendToOFD, SelObjReturn.PhoneToSendToOFD);
		EndIf;
	Else
		// Device driver was not found
		rMessage = Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'");
	EndIf;
	Return False;
EndFunction // StartPrintCheque

// -----------------------------------------------------------------------------
&AtServer
Procedure FillObjectByDocument(pDocument, pType)
	vObj = pDocument.GetObject();
	If pType = "Payment" Then
		ValueToFormAttribute(vObj, "SelObjPayment");
	ElsIf pType = "CustomerPayment" Then
		ValueToFormAttribute(vObj, "SelObjCustomerPayment");
	Else
		ValueToFormAttribute(vObj, "SelObjReturn");
	EndIf;
EndProcedure // FillObjectByDocument

#EndRegion

