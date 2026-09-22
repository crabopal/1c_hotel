
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	If ValueIsFilled(Object.ParentCharge) And ValueIsFilled(Object.ParentCharge.Folio) And Object.ParentCharge.Folio.IsClosed Then
		If ValueIsFilled(Object.Ref) Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		Else
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		If Object.Posted Then
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
				If BegOfDay(vAccountingDate) > BegOfDay(Object.Date) Or Object.Author <> SessionParameters.CurrentUser Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;
			// Check if this storno is closed to edit
			If ValueIsFilled(Object.Hotel) Then
				vHotel = Object.Hotel;
				If vHotel.DoNotEditSettledDocs And 
				  (Object.Sum <> 0 Or Object.Quantity <> 0) And ValueIsFilled(Object.ParentCharge) And ValueIsFilled(Object.ParentCharge.Folio) And 
				   Object.ParentCharge.Folio.IsClosed Then
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
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='This document is closed by settlement! Document will be opened read only.';ru='Сторно уже закрыто актом об оказании услуг! Редактирование такого документа запрещено.';de='Das Dokument wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Dokument ist verboten.'"));
					EndIf;
				ElsIf vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) Then
					If cmIfChargeIsInClosedDay(Object.Ref) Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='This document is in closed day! Document will be opened read only.';ru='Сторно в закрытом дне! Редактирование такого документа запрещено.';de='Das Dokument ist in geschlossener Tag! Die Bearbeitung einer solchen Dokument ist verboten.'"));
					Endif;
				EndIf;
			EndIf;
		Else
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
	Else
		Items.FormSetDeletionMarkAction.Visible = False;
	EndIf;
	
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	vFormTitle = "";
	If ValueIsFilled(Object.Ref) Then
		vFormTitle = " - " + TrimAll(Object.Author);
		If Not IsBlankString(vFormTitle) Then
			AutoTitle = False;
			Title = TrimAll(Object.Ref) + vFormTitle;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.Storno.Write", Object.Ref, ThisObject);
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
		If Object.DeletionMark Then
			Notify("Document.Storno.SetDeletionMark", Object.Ref, ThisObject);
		EndIf;
	EndIf;
EndProcedure // OnClose

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
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
	
	vMessage = ""; 
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		If Not CheckDocumentAttributesAtServer(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'Document.Posting'; de = 'Document.Posting'; ru = 'Документ.Проведение'"), , , , tcOnServer.cmNStrAtServer(vMessage));
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
EndProcedure // BeforeWrite

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
	Notify("Document.Storno.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then   
		tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr);
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

#EndRegion
