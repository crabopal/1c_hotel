
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	vFormTitle = "";
	If ValueIsFilled(Object.Ref) Then
		vFormTitle = " - " + TrimAll(Object.Author);
		If Not IsBlankString(vFormTitle) Then
			AutoTitle = False;
			Title = TrimAll(Object.Ref) + vFormTitle;
		EndIf;
	EndIf;
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	If ValueIsFilled(Object.FolioFrom) And Object.FolioFrom.IsClosed Or
	   ValueIsFilled(Object.FolioTo) And Object.FolioTo.IsClosed Then
		If ValueIsFilled(Object.Ref) Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		Else
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
	EndIf;
	// Set view only mode
	If ValueIsFilled(Object.Ref) Then
		If Object.Posted Then
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
				If BegOfDay(vAccountingDate) > BegOfDay(Object.Date) Or Object.Author <> SessionParameters.CurrentUser Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;
			// Check if this charge is closed to edit
			If ValueIsFilled(Object.Hotel) Then
				vHotel = Object.Hotel;
				If vHotel.DoNotEditSettledDocs And ValueIsFilled(Object.ParentCharge) And 
				  (Object.ParentCharge.Sum <> 0 Or Object.ParentCharge.Quantity <> 0) And ValueIsFilled(Object.ParentCharge.Folio) And Object.ParentCharge.Folio.IsClosed Then
					vChargeBalanceIsZero = False;
					vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(Object.ParentCharge);
					If vChargeBalancesRow <> Undefined Then
						If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
							vChargeBalanceIsZero = True;
						EndIf;
					Else
						vChargeBalanceIsZero = True;
					EndIf;
					If vChargeBalanceIsZero Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
					EndIf;
				ElsIf vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) Then
					If cmIfChargeIsInClosedDay(Object.Ref) Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
					Endif;
				EndIf;
			EndIf;
		Else
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
	Else
		Items.FormSetDeletionMarkAction.Visible = False;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure //  OnCreateAtServer()

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.ChargeTransfer.Write", Object.Ref, ThisObject);
EndProcedure //  AfterWrite()

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure //  OnCloseAtServer()

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
		If Object.DeletionMark Then
			Notify("Document.ChargeTransfer.SetDeletionMark", Object.Ref, ThisObject);
		EndIf;
	EndIf;
EndProcedure //  OnClose()

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If Not ValueIsFilled(Object.Ref) Then
			Object.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
		If pParameter.ModeAfterCheck = "BeforeWrite" Then
			If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing()

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
	
	vMessage = ""; 
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		If Not CheckDocumentAttributesAtServer(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
			Return;
		EndIf;
		vMessage = "";
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeWrite"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			pCancel = True;
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
	EndIf;
EndProcedure //  BeforeWrite()

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
	Notify("Document.ChargeTransfer.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure //  SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), , vAttributeInErr);
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction //  CheckDocumentAttributesAtServer()

#EndRegion
