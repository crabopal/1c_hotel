
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Parameters.RoomRevenueCharge) Then
		pCancel = True;
		Return;
	EndIf;
	RoomRevenueCharge = Parameters.RoomRevenueCharge;
	RoomRateCharges.Parameters.SetParameterValue("qRoomRevenueCharge", RoomRevenueCharge);
	GetRoomRateAmountAtServer();
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If pParameter.ModeAfterCheck = "Storno" Then
			Storno(Commands.Storno);
		EndIf;
	Else
		RoomRateCharges.Parameters.SetParameterValue("qRoomRevenueCharge", RoomRevenueCharge);
		GetRoomRateAmountAtServer();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRateChargesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pSelectedRow <> Undefined Then
		If pField = Items.RoomRateChargesFolio Then
			ShowValue(, Items.RoomRateCharges.RowData(pSelectedRow).Folio);
		ElsIf pField = Items.RoomRateChargesParentDoc Then
			ShowValue(, Items.RoomRateCharges.RowData(pSelectedRow).ParentDoc);
		Else
			ShowValue(, Items.RoomRateCharges.RowData(pSelectedRow).Ref);
		EndIf;
	EndIf;
EndProcedure // RoomRateChargesSelection

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure Storno(pCommand)
	ClearMessages();
	If Not ValueIsFilled(RoomRevenueCharge) Then
		Return;
	EndIf;
	// Fill list of selected charges
	vCharges = New Array;
	For Each vRowID In Items.RoomRateCharges.SelectedRows Do
		vRowData = Items.RoomRateCharges.RowData(vRowID);
		If TypeOf(vRowData.Ref) <> Type("DocumentRef.Charge") Then
			Continue;
		EndIf;
		vCharges.Add(vRowData.Ref);
	EndDo;
	GetAllowedChargesForOperation(vCharges);
	// Delete from the array charges that have already being canceled
	vFolio = tcOnServer.cmGetAttributeByRef(RoomRevenueCharge, "Folio");
	If CheckUserPermissionsForStorno(vFolio) And vCharges.Count() > 0 Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Storno"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		
		vLabelDescription = NStr("en = 'Choose type of reversal...'; de = 'Geben Sie den Stornotyp an...'; ru = 'Укажите тип сторно...'");
		vParameters = New Structure("Folio, ChargesArray", vFolio, vCharges);
		vCallbackDescription = New NotifyDescription("AfterInputCancelActionType", ThisObject, vParameters);
		OpenForm("CommonForm.tcInputCancelActionType", New Structure("LabelDescription", vLabelDescription), ThisObject, , , , vCallbackDescription, FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure // Storno

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure UnbindAll(Command)
	ClearMessages();
	If Not ValueIsFilled(RoomRevenueCharge) Then
		Return;
	EndIf;
	// Fill list of selected charges
	vCharges = GetRoomRateTransactions(RoomRevenueCharge);
	GetAllowedChargesForOperation(vCharges);
	// Delete from the array charges that have already being canceled
	vFolio = tcOnServer.cmGetAttributeByRef(RoomRevenueCharge, "Folio");
	If CheckUserPermissionsForUnbind(vFolio) And vCharges.Count() > 0 Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "UnbindAll"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		
		// Do at server
		vErrorText = UnbindAllAtServer(vCharges);
		If Not IsBlankString(vErrorText) Then
			ShowMessageBox(, vErrorText, , NStr("en='Error!'; ru='Ошибка!'; de='Fehler!'"));
			Items.RoomRateCharges.Refresh();
		Else
			Notify("Document.Charge.Write", RoomRevenueCharge, ThisObject);
			Close();
		EndIf;
	EndIf;
EndProcedure // UnbindAll

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure GetRoomRateAmountAtServer()
	RoomRateSum = 0;
	RoomRateDiscountSum = 0;
	RoomRateCommissionSum = 0;
	RoomRateAmount = 0;
	RoomRateVATSum = 0;
	vRoomRateAmountsRow = cmGetRoomRateAmounts(RoomRevenueCharge);
	If vRoomRateAmountsRow <> Undefined Then
		RoomRateSum = vRoomRateAmountsRow.Sum;
		RoomRateDiscountSum = vRoomRateAmountsRow.DiscountSum;
		RoomRateCommissionSum = vRoomRateAmountsRow.CommissionSum;
		RoomRateAmount = vRoomRateAmountsRow.Amount;
		RoomRateVATSum = vRoomRateAmountsRow.VATSum;
	EndIf;
EndProcedure // GetRoomRateAmountAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GetAllowedChargesForOperation(pChargesArray)
	i = 0;
	While i < pChargesArray.Count() Do
		vCharge = pChargesArray.Get(i);
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	Stornos.Ref AS Ref
		|FROM
		|	Document.Storno AS Stornos
		|WHERE
		|	Stornos.Posted
		|	AND (Stornos.ParentCharge = &qCharge
		|			OR &qRoomRevenueChargeIsFilled
		|				AND Stornos.ParentCharge = &qRoomRevenueCharge)
		|
		|UNION ALL
		|
		|SELECT
		|	Corrections.Ref
		|FROM
		|	Document.Charge AS Corrections
		|WHERE
		|	Corrections.Posted
		|	AND (Corrections.CorrectedCharge = &qCharge
		|			OR &qRoomRevenueChargeIsFilled
		|				AND Corrections.CorrectedCharge = &qRoomRevenueCharge)";
		vQry.SetParameter("qCharge", vCharge);
		vQry.SetParameter("qRoomRevenueChargeIsFilled", ValueIsFilled(vCharge.RoomRevenueCharge));
		vQry.SetParameter("qRoomRevenueCharge", vCharge.RoomRevenueCharge);
		vQryRes = vQry.Execute();
		If Not vQryRes.IsEmpty() Then
			tcCommonFunctionOnClientServer.UserMessage(Nstr(StrTemplate("en = 'Corrections or reversals were made for the charge %1! Operation for service ""%2"" is not possible.'; 
									                                    |de = 'Korrekturen oder Umkehrungen wurden für die Dokument von %1 vorgenommen! Eine Bedienung für Service ""%2"" ist nicht möglich.'; 
									                                    |ru = 'Для начисления %1 уже сделаны корректировки или отмены! Операция по услуге ""%2"" невозможна.'", 
			                                                            vCharge.Number, vCharge.Service)));
			pChargesArray.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
EndProcedure // GetAllowedChargesForOperation

// ------------------------------------------------------------------------------------------------
&AtClient
Function CheckUserPermissionsForStorno(pFolio)
	If ValueIsFilled(pFolio) And tcOnServer.cmGetAttributeByRef(pFolio, "IsClosed") Then
		ShowMessageBox(, NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Personenkonto geschlossen ist!'"));
		Return False;
	EndIf;
	
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStornoFolioCharges") Then
		ShowMessageBox(,NStr("en = 'You do not have rights to do reversals for charges!'; 
							 |de = 'Sie haben keine Rechte, Berechnungen zu stornieren!'; 
							 |ru = 'Нет прав на сторнирование начислений!'"));
		Return False;
	EndIf;
	
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCustomerFolioTransactions") Then
		vFolioPaymentMethod = tcOnServer.cmGetAttributeByRef(pFolio, "PaymentMethod");
		If ValueIsFilled(vFolioPaymentMethod) Then
			vIsByBankTransfer = tcOnServer.cmGetAttributeByRef(vFolioPaymentMethod, "IsByBankTransfer");
			If vIsByBankTransfer Then
				ShowMessageBox(, NStr("en = 'You do not have rights to change customer folio transactions set!'; 
									  |de = 'Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'; 
									  |ru = 'Нет прав на изменение набора транзакций по лицевым счетам контрагентов!'"));
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction	// CheckUserPermissionsForStorno

// ------------------------------------------------------------------------------------------------
&AtClient
Function CheckUserPermissionsForUnbind(pFolio)
	If ValueIsFilled(pFolio) And tcOnServer.cmGetAttributeByRef(pFolio, "IsClosed") Then
		ShowMessageBox(, NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Personenkonto geschlossen ist!'"));
		Return False;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCustomerFolioTransactions") Then
		vFolioPaymentMethod = tcOnServer.cmGetAttributeByRef(pFolio, "PaymentMethod");
		If ValueIsFilled(vFolioPaymentMethod) Then
			vIsByBankTransfer = tcOnServer.cmGetAttributeByRef(vFolioPaymentMethod, "IsByBankTransfer");
			If vIsByBankTransfer Then
				ShowMessageBox(, NStr("en = 'You do not have rights to change customer folio transactions set!'; 
									  |de = 'Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'; 
									  |ru = 'Нет прав на изменение набора транзакций по лицевым счетам контрагентов!'"));
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction	// CheckUserPermissionsForUnbind

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterInputCancelActionType(pAnswer, pAdditionalParameters) Export
	If Not pAnswer = Undefined Then
		vErrorText = StornoAtServer(pAdditionalParameters.ChargesArray, pAnswer.TypeOfStorno, pAnswer.Remarks);
		If Not IsBlankString(vErrorText) Then
			ShowMessageBox(, vErrorText, , NStr("en = 'Error!'; de = 'Fehler!'; ru = 'Ошибка!'"));
		Else
			Notify("Document.Charge.Write", RoomRevenueCharge, ThisObject);
		EndIf;
		Items.RoomRateCharges.Refresh();
	EndIf;
EndProcedure // AfterInputCancelActionType

// ------------------------------------------------------------------------------------------------
&AtServer
Function StornoAtServer(pDocsArray, pTypeOfStorno, pRemarks)
	vErrorText = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vDocRef In pDocsArray Do
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"),, 
													"Documents.Storno", "Documents.Storno.EmptyRef()", 
													 NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
													 
			vStornoObj = Documents.Storno.CreateDocument();
			vStornoObj.Fill(vDocRef);
			vStornoObj.SetTime(AutoTimeMode.CurrentOrLast);
			vStornoObj.Date = CurrentSessionDate();
			vStornoObj.TypeOfStorno = ?(pTypeOfStorno=0,Enums.CancelActionTypes.ClientRefusal,Enums.CancelActionTypes.EmployeeFault);
			vStornoObj.Remarks = pRemarks;
			vStornoObj.Write(DocumentWriteMode.Posting);
			
			If ValueIsFilled(vDocRef.RoomRevenueCharge) And vDocRef.RoomRevenueCharge.Posted Then
				vRevenueChargeObj = vDocRef.RoomRevenueCharge.GetObject();
				vRevenueChargeObj.RateSum = vRevenueChargeObj.RateSum - vDocRef.Sum;
				vRevenueChargeObj.RateDiscountSum = vRevenueChargeObj.RateDiscountSum - vDocRef.DiscountSum;
				vRevenueChargeObj.RateCommissionSum = vRevenueChargeObj.RateCommissionSum - vDocRef.CommissionSum;
				vRevenueChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		vErrorText = cmGetRootErrorDescription(vErrorInfo);
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorText;
EndFunction // StornoAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Function UnbindAllAtServer(pDocsArray)
	vErrorText = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vDocRef In pDocsArray Do
			vChargeObj = vDocRef.GetObject();
			vChargeObj.IsMergedToRoomRevenue = False;
			vChargeObj.Write(DocumentWriteMode.Posting);
		EndDo;
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		vErrorText = cmGetRootErrorDescription(vErrorInfo);
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorText;
EndFunction // UnbindAllAtServer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomRateTransactions(pRoomRevenueCharge)
	vCharges = New Array();
	vTransactions = cmGetRoomRateTransactions(pRoomRevenueCharge);
	For Each vTransactionsRow In vTransactions Do
		If TypeOf(vTransactionsRow.Ref) = Type("DocumentRef.Charge") Then
			vCharges.Add(vTransactionsRow.Ref);
		EndIf;
	EndDo;
	Return vCharges;
EndFunction // GetRoomRateTransactions

#EndRegion
