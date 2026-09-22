
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing) 
	IsHotelOnlineBooking = False;
	
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	vParametersStructure = Undefined;
	Parameters.Property("ParametersStructure", vParametersStructure);
	If vParametersStructure <> Undefined Then
		If vParametersStructure.Property("DocRef") Then
			ObjectRef = vParametersStructure.DocRef;
		ElsIf vParametersStructure.Property("ObjectRef") Then
			ObjectRef = vParametersStructure.ObjectRef;
		EndIf;
	EndIf;
	If ObjectRef = Undefined Then
		pCancel = True;    
		Return;
	EndIf;
	SelHideCorrections = False;
	Items.SelHideCorrections.Visible = tcOnServer.cmGetHideCorrectionVisibility(SessionParameters.CurrentHotel);
	
	ObjectRefRemarks = "";
	Items.ParentDocDecoration.Title = "";
	FolioPageTypeLeft = 0;
	FolioPageTypeRight = 0;
	If Not ObjectRef = Undefined Then
		If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
			ObjectRefRemarks = TrimAll(ObjectRef.Remarks);
			Title = NStr("en='Room: ';ru='Номер: ';de='Zimmer: '") + TrimAll(ObjectRef.Room) + NStr("en='; guest group: ';ru='; группа гостей: ';de='; Gästegruppe: '") + TrimAll(ObjectRef.GuestGroup) + 
			                 NStr("en='; period '; ru='; период ';de=' Periode '") + Format(ObjectRef.CheckInDate, "DF=dd.MM.yy") + " - " + Format(ObjectRef.CheckOutDate, "DF=dd.MM.yy");
			Items.ParentDocDecoration.Title = TrimAll(ObjectRef);   
			MainGuest = ObjectRef.Guest; 
		ElsIf TypeOf(ObjectRef) = Type("DocumentRef.ResourceReservation") Then
			ObjectRefRemarks = TrimAll(ObjectRef.Remarks);
			Title = NStr("en='Resource: ';ru='Ресурс: ';de='Ressource: '") + TrimAll(ObjectRef.Resource) + NStr("en='; guest group: ';ru='; группа гостей: ';de='; Gästegruppe: '") + TrimAll(ObjectRef.GuestGroup) + 
			                 NStr("en='; period '; ru='; период ';de=' Periode '") + Format(ObjectRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(ObjectRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
			Items.ParentDocDecoration.Title = TrimAll(ObjectRef); 
			MainGuest = ObjectRef.Client; 
		Else
			Title = TrimAll(ObjectRef);
			Items.ParentDocDecoration.Title = "";
		EndIf;
		If TypeOf(ObjectRef) = Type("DocumentRef.Folio") Then  
			MainGuest = ObjectRef.Client;
		ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Clients") Then  
			MainGuest = ObjectRef; 
		ElsIf TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then  
			FolioPageTypeLeft = 3;
			FolioPageTypeRight = 3;	
		EndIf;	
		
		ParentDoc = Undefined;
		If Parameters.Property("ParentDoc") And ValueIsFilled(Parameters.ParentDoc) Then
			ParentDoc = Parameters.ParentDoc;
		EndIf;
	EndIf;
	
	// Control visibility
	Items.CheckOut.Visible = TypeOf(ObjectRef) = Type("DocumentRef.Accommodation");
	ActveWindowName = "";
	Items.GroupLeftPanelPresentation.BackColor = GetSelectedFolioColor();
	Items.GroupLeftPanelPresentationBorder.BackColor = GetSelectedFolioColor();
	Items.GroupRightPanelPresentation.BackColor = GetSelectedFolioColor();
	Items.GroupRightPanelPresentationBorder.BackColor = GetSelectedFolioColor();
	
	// Get parameters for advance and advance settlement
	AdvancePaymentSection = Undefined;
	AdvanceSettlementPaymentMethod = Undefined;
	cmFillAdvanceAndAdvanceSettlementParameters(SessionParameters.CurrentHotel, SessionParameters.CurrentUser, AdvancePaymentSection, AdvanceSettlementPaymentMethod);
	If Not ValueIsFilled(AdvancePaymentSection) Or Not ValueIsFilled(AdvanceSettlementPaymentMethod) Then
		Items.AdvanceSettlementChequeLeft.Visible = False;
		Items.AdvanceSettlementChequeRight.Visible = False;
	EndIf;
	
	If ObjectRef = Undefined Then
		pCancel = True;
		Return;
	EndIf;
	
	If Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(SessionParameters.CurrentHotel) <> Undefined Then
		vVisibleGetPaid =  True;
	Elsif Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SessionParameters.CurrentHotel) <> Undefined Then
		vVisibleGetPaid =  True;
		IsHotelOnlineBooking = True;
	Else
		vVisibleGetPaid =  False;
	EndIf;

	Items.GetPaidLeft.Visible = vVisibleGetPaid;
	Items.GetPaidRight.Visible = vVisibleGetPaid;
	Items.Split.TitleLocation = FormItemTitleLocation.Left;
	Items.Split.CheckBoxType = CheckBoxType.Switch;
	
	UpdatePanelsOnServer(); 
	
	// Fill printing forms
	FillListOfObjectPrintingForms();
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	// Check clipboard and show it's content if is set
	ControlVisibility();
	
	If TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Or TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or 
	   TypeOf(ObjectRef) = Type("CatalogRef.Customers") Or TypeOf(ObjectRef) = Type("CatalogRef.Clients") Then
		vTasksStructure = GetTasksStructure(ObjectRef);
		For Each vTasks In vTasksStructure Do
			vTaskStruct = vTasks.Value;
			If vTaskStruct.PopUp Then
				vShow = True;
				If TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Or TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Then
					If ValueIsFilled(vTaskStruct.ReservationTaskArea) Then
						vCheckInDate = tcOnServer.cmGetAttributeByRef(ObjectRef, "CheckInDate");
						vCheckOutDate = tcOnServer.cmGetAttributeByRef(ObjectRef, "CheckOutDate");
						If vTaskStruct.ReservationTaskArea = PredefinedValue("Enum.ReservationTaskAreas.CheckIn") Then
							If BegOfDay(CurrentDate()) > BegOfDay(vCheckInDate) Then
								vShow = False;
							EndIf;
						ElsIf vTaskStruct.ReservationTaskArea = PredefinedValue("Enum.ReservationTaskAreas.CheckOut") Then
							If BegOfDay(CurrentDate()) < BegOfDay(vCheckOutDate) Then
								vShow = False;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vShow Then
					ShowMessageBox(, vTasks.Value.Remarks, , NStr("en='Task';de='Aufgabe';ru='Задача'"));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	DetachIdleHandler("RefreshTransactionsLists");
	OnReopenAtServer();
EndProcedure

 // -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Folio.Edit" Then
		UpdatePanelsOnServer(True, False, False);
		// Fill printing forms
		FillListOfObjectPrintingForms();
	ElsIf pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If pParameter.ModeAfterCheck = "StornoLeft" Then
			StornoLeft(Commands.StornoLeft);
		ElsIf pParameter.ModeAfterCheck = "StornoRight" Then
			StornoLeft(Commands.StornoRight);
		ElsIf pParameter.ModeAfterCheck = "CorrectionLeft" Then
			CorrectionLeft(Commands.CorrectionLeft);
		ElsIf pParameter.ModeAfterCheck = "CorrectionRight" Then
			CorrectionRight(Commands.CorrectionRight);
		ElsIf pParameter.ModeAfterCheck = "PasteLeft" Then
			PasteLeft(Commands.PasteLeft);
		ElsIf pParameter.ModeAfterCheck = "PasteRight" Then
			PasteRight(Commands.PasteRight);
		ElsIf pParameter.ModeAfterCheck = "FolioDocumentsLeftDrag" Then
			FolioDocumentsLeftDrag(pParameter.Item, pParameter.DragParameters, True, pParameter.Row, pParameter.Field);
		ElsIf pParameter.ModeAfterCheck = "FolioDocumentsRightDrag" Then
			FolioDocumentsRightDrag(pParameter.Item, pParameter.DragParameters, True, pParameter.Row, pParameter.Field);
		ElsIf pParameter.ModeAfterCheck = "BindToAccommodationLeft" Then
			BindToAccommodationLeft(Commands.BindToAccommodationLeft);
		ElsIf pParameter.ModeAfterCheck = "BindToAccommodationRight" Then
			BindToAccommodationRight(Commands.BindToAccommodationRight);
		EndIf;
	ElsIf pEventName = "Document.Payment.OpenForm" Then
		OpenForm("Document.Payment.ObjectForm", pParameter, ThisObject, pSource, , , , FormWindowOpeningMode.LockOwnerWindow);
	ElsIf pEventName = "Document.Return.OpenForm" Then
		OpenForm("Document.Return.ObjectForm", pParameter, ThisObject, pSource, , , , FormWindowOpeningMode.LockOwnerWindow);
	ElsIf pEventName = "TransferOperation.Start" Then
		If pSource <> ThisObject Then
			ControlVisibility();
		EndIf;
	ElsIf pEventName = "TransferOperation.End" Then
		If pSource <> ThisObject Then
			// Clear clipboard
			amClipboard.Delete("TransferTransactionsType");
			amClipboard.Delete("TransferTransactions");
			amClipboard.Delete("TransferFolioFrom");
			// Set form items appearance
			ControlVisibility();
			// Refresh transactions
			AttachIdleHandler("RefreshTransactionsLists", 1, True);
		EndIf;
	ElsIf pEventName = "System.Hotel.Changed" And ValueIsFilled(FolioRefLeft) And tcOnServer.cmGetAttributeByRef(FolioRefLeft, "Hotel") <> pParameter Then
		Close();
	ElsIf pEventName = "Folios.SharedGuestsSelection" And TypeOf(pParameter) = Type("Structure") And 
	      pParameter.Property("SelectedGuests") And TypeOf(pParameter.SelectedGuests) = Type("Array") And pParameter.SelectedGuests.Count() > 0 And 
		  pParameter.Property("FoliosPage") And pSource = ThisObject Then
		vNameButton = "";
		vSelectedAccompanyGuests = Undefined;
		If pParameter.FoliosPage = "Right" Then
			vNameButton = "AccompanyGuestRight";
			vButtonArr = StrSplit("CurrentGuestFoliosRight,AccompanyGuestRight,MasterFoliosRight,GuestGroupsFoliosRight", ",");
			vSelectedAccompanyGuests = SelectedAccompanyGuestsRight;
		Else
			vNameButton = "AccompanyGuestLeft";
			vButtonArr = StrSplit("CurrentGuestFoliosLeft,AccompanyGuestLeft,MasterFoliosLeft,GuestGroupsFoliosLeft", ",");
			vSelectedAccompanyGuests = SelectedAccompanyGuestsLeft;
		EndIf;
		vSelectedAccompanyGuests.Clear();
		For Each vSelectedGuestsStruct In pParameter.SelectedGuests Do
			vGuestRow = vSelectedAccompanyGuests.Add();
			FillPropertyValues(vGuestRow, vSelectedGuestsStruct);
		EndDo;
		Items[vNameButton].Check = True;
		Items[vNameButton].ShapeRepresentation = ButtonShapeRepresentation.Auto; 
		For Each vBtn In vButtonArr Do
			If vNameButton <> vBtn Then
				Items[vBtn].Check = False;	
				Items[vBtn].ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
			EndIf;	
		EndDo;  
		If pParameter.FoliosPage = "Right" Then
			FolioPageTypeRight = 1;
			UpdatePanelsOnServer(False, False, True);
		Else
			FolioPageTypeLeft = 1;
			UpdatePanelsOnServer(False, True, False);
		EndIf;
	Else
		// Check if we need to print receipt
		If ValueIsFilled(pParameter <> Undefined) Then
			If pEventName = "Document.Charge.Write" Or 
			   pEventName = "Document.Payment.Write" Or
			   pEventName = "Document.Preauthorisation.Write" Or
			   pEventName = "Document.DepositTransfer.Write" Or
			   pEventName = "Document.Return.Write" Or 
			   pEventName = "Document.BonusesPayment.Write" Then
				vPrtForm = Undefined;
				If NeedToPrintReceipt(vPrtForm) And pEventName <> "Document.DepositTransfer.Write" And pEventName <> "Document.BonusesPayment.Write" Then
					vFormPrintSettings = GetReceiptPrintSettings(vPrtForm);
					vFolio = Undefined;
					vFirstDoc = Undefined;
					vTransArray = New Array;
					If TypeOf(pParameter) <> Type("Array") Then
						vTransArray.Add(pParameter);
						vFirstDoc = pParameter;
					Else
						vTransArray = pParameter;
						vFirstDoc = pParameter.Get(0);
					EndIf;
					vPosted = tcOnServer.cmGetAttributeByRef(vFirstDoc, "Posted");
					If vPosted Then
						vFolio = tcOnServer.cmGetAttributeByRef(vFirstDoc, "Folio");
						vLanguage = GetLanguageByFolio(vFolio);
						
						PrintReceipt(vFolio, vLanguage, vTransArray, vFormPrintSettings);
					EndIf;
				EndIf;
				If pEventName <> "Document.Preauthorisation.Write" And pEventName <> "Document.Charge.Write" And pEventName <> "Document.BonusesPayment.Write" Then
					If TypeOf(pParameter) <> Type("Array") Then
						vDoc = pParameter;
						If ValueIsFilled(vDoc) Then
							vHotel = tcOnServer.cmGetAttributeByRef(vDoc, "Hotel");
							If ValueIsFilled(vHotel) Then
								vPaymentsGenerateInvoices = tcOnServer.cmGetAttributeByRef(vHotel, "PaymentsGenerateInvoices");
								vInvoice = tcOnServer.cmGetAttributeByRef(vDoc, "Invoice");
								If vPaymentsGenerateInvoices And ValueIsFilled(vInvoice) Then
									vPrintForm = Undefined;
									vLanguage = tcOnServer.cmGetAttributeByRef(vHotel, "Language");
									If TypeOf(vInvoice) = Type("DocumentRef.ProformaInvoice") Then
										vPrintForm = tcOnServer.GetProformaInvoiceDefaultPrintForm(vLanguage);
									ElsIf TypeOf(vInvoice) = Type("DocumentRef.Settlement") Then
										vPrintForm = tcOnServer.GetInvoiceDefaultPrintForm(vLanguage);
									EndIf;
									If ValueIsFilled(vPrintForm) Then
										vAutomaticallyPrintOnFirstObjectWrite = tcOnServer.cmGetAttributeByRef(vPrintForm, "AutomaticallyPrintOnFirstObjectWrite");
										If vAutomaticallyPrintOnFirstObjectWrite Then
											If TypeOf(vInvoice) = Type("DocumentRef.ProformaInvoice") Then
												OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", vInvoice, True, vLanguage), , vInvoice);
											ElsIf TypeOf(vInvoice) = Type("DocumentRef.Settlement") Then
												OpenForm("Document.Settlement.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", vInvoice, True, vLanguage), , vInvoice);
											EndIf;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If pEventName <> "CheckIn" Then
			AttachIdleHandler("RefreshTransactionsLists", 1, True);
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	// Check if form is active
	ChargeServiceByBarcode(vEventData.DeviceData);
EndProcedure // ExternalEvent

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("Invoice") And pSelectedValue.Property("RefillInvoice") Then
		ChosenInvoice = pSelectedValue.Invoice;
		RefillInvoice = pSelectedValue.RefillInvoice;
		GetPaidClick(Items[pSelectedValue.ItemName]);
		ChosenInvoice = Undefined;
		RefillInvoice = False;
	EndIf;
EndProcedure // ChoiceProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GetPaidClick(pItem)
	vTree = Undefined;
	vIsCheckedColumn = False;
	vFolio = Undefined;
	If pItem.Name = "GetPaidLeft" Then 
		vFolio = FolioRefLeft;
		vTree = "FolioDocumentsLeft";
		vIsCheckedColumn = Items.FolioDocumentsLeftIsChecked.Visible;
	Else
		vFolio = FolioRefRight;
		vTree = "FolioDocumentsRight";
		vIsCheckedColumn = Items.FolioDocumentsRightIsChecked.Visible;
	EndIf;
	If ValueIsFilled(vFolio) Then
		If IsHotelOnlineBooking Then
			If CheckIfProformaInvoicesExist(vFolio) And Not RefillInvoice Then
				vStruct = GetNumberAndSumOfServices(vTree, vIsCheckedColumn, vFolio);
				vParams = New Structure("Folio, ItemName, Number, Sum, Currency", vFolio, pItem.Name, vStruct.Number, vStruct.Sum, vStruct.Currency); 
				OpenForm("CommonForm.tcCheckInvoice", vParams, ThisObject, UUID); 
				Return;
			EndIf;
			vDocRef = CreateNewOrEditExistingProformaInvoice(vTree, vIsCheckedColumn, vFolio);
			If ValueIsFilled(vDocRef) Then
				vParams = New Structure("SelDocument", vDocRef); 
				OpenForm("CommonForm.tcGetPaidForm", vParams, ThisObject, vDocRef);
			EndIf;
		Else
			vParams = New Structure("SelDocument", vFolio);
			OpenForm("CommonForm.tcGetPaidForm", vParams, ThisObject, vFolio);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Folio is not selected!'; de = 'Folio ist nicht ausgewählt!'; ru = 'Не выбран лицевой счет!'"));
	EndIf;
EndProcedure // GetPaidClick

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure ParentDocDecorationClick(Item)
	If ValueIsFilled(ObjectRef) Then
		If TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
			OpenForm("Document.Reservation.ObjectForm", New Structure("Key", ObjectRef), ThisObject, ObjectRef);
		ElsIf TypeOf(ObjectRef) = Type("DocumentRef.ResourceReservation") Then
			OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", ObjectRef), ThisObject, ObjectRef);
		ElsIf TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Then
			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", ObjectRef), ThisObject, ObjectRef);
		Else
			ShowValue(, ObjectRef);
		EndIf;
	EndIf;
EndProcedure // ParentDocDecorationClick

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitOnChange(Item)
	Items.GroupRightPanel.Visible = Split;
	Items.LeftPanelBalance.Hyperlink = Split;
	Items.RightPanelBalance.Hyperlink = Split;
	If Split Then
		UpdatePanelsOnServer(False, False);    
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LeftPanelFolioNumberClick(Item)
	OpenForm("Document.Folio.ObjectForm", New Structure("Key",FolioRefLeft),,,,,,FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RightPanelFolioNumberClick(Item)
	OpenForm("Document.Folio.ObjectForm", New Structure("Key",FolioRefRight),,,,,,FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectFolioLeft(pItem)
	vUUID = pItem.Name;
	If StrFind(vUUID, "FormDecorationBalanceFolioDocumentsLeft_") > 0 Then
		vUUID = StrReplace(vUUID, "FormDecorationBalanceFolioDocumentsLeft_", "");
	ElsIf StrFind(pItem.Name, "FormDecorationPreauthLimitFolioDocumentsLeft_") > 0 Then
		vUUID = StrReplace(vUUID, "FormDecorationPreauthLimitFolioDocumentsLeft_", "");
	Else
		vUUID = "";
	EndIf;
	If IsBlankString(vUUID) Then
		Return;
	EndIf;
	vUUID = StrReplace(vUUID,"_","-");
	vFolio = GetFolioRefByUUID(vUUID);
	If Not vFolio = Undefined Then
		If FolioRefLeft <> vFolio Then 
			vStr = FolioList.FindByValue(vFolio);
			If vStr <> Undefined Then   
				FolioRefLeft = vFolio;
				// Header    
				FillPresentationFoliosList("FolioDocumentsLeft", False);
				FillLeftPanelHeader(vFolio);
				FillFolioPage(vFolio, "FolioDocumentsLeft");
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectFolioRight(pItem)
	vUUID = pItem.Name;
	If StrFind(vUUID, "FormDecorationBalanceFolioDocumentsRight_") > 0 Then
		vUUID = StrReplace(vUUID, "FormDecorationBalanceFolioDocumentsRight_", "");
	ElsIf StrFind(pItem.Name, "FormDecorationPreauthLimitFolioDocumentsRight_") > 0 Then
		vUUID = StrReplace(vUUID, "FormDecorationPreauthLimitFolioDocumentsRight_", "");
	Else
		vUUID = "";
	EndIf;
	If IsBlankString(vUUID) Then
		Return;
	EndIf;
	vUUID = StrReplace(vUUID,"_","-");
	vFolio = GetFolioRefByUUID(vUUID);
	If Not vFolio = Undefined Then
		If FolioRefRight <> vFolio Then 
			vStr = FolioList.FindByValue(vFolio);
			If vStr <> Undefined Then   
				FolioRefRight = vFolio;
				// Header    
				FillPresentationFoliosList("FolioDocumentsRight", False);
				FillRightPanelHeader(vFolio);
				FillFolioPage(vFolio, "FolioDocumentsRight");
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceLeftClick(pItem, pStandardProcessing)
	If ValueIsFilled(InvoiceLeft) Then
		If TypeOf(InvoiceLeft) = Type("DocumentRef.ProformaInvoice") Then
			pStandardProcessing = False;
			OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", InvoiceLeft, True, InvoiceLanguageLeft), , InvoiceLeft);
		ElsIf TypeOf(InvoiceLeft) = Type("DocumentRef.Settlement") Then
			pStandardProcessing = False;
			OpenForm("Document.Settlement.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", InvoiceLeft, True, InvoiceLanguageLeft), , InvoiceLeft);
		EndIf;
	EndIf;
EndProcedure // InvoiceLeftClick

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceRightClick(pItem, pStandardProcessing)
	If ValueIsFilled(InvoiceRight) Then
		If TypeOf(InvoiceRight) = Type("DocumentRef.ProformaInvoice") Then
			pStandardProcessing = False;
			OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", InvoiceRight, True, InvoiceLanguageRight), , InvoiceRight);
		ElsIf TypeOf(InvoiceRight) = Type("DocumentRef.Settlement") Then
			pStandardProcessing = False;
			OpenForm("Document.Settlement.ObjectForm", New Structure("Key, PrintOnOpen, PrintFormLanguage", InvoiceRight, True, InvoiceLanguageRight), , InvoiceRight);
		EndIf;
	EndIf;
EndProcedure // InvoiceRightClick

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowTransfersOnChange(pItem)
	UpdatePanelsOnServer(False);
EndProcedure // SelShowTransfersOnChange

#EndRegion

#Region FormTableItemsEventHandlers

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsLeftDrag(Item, pDragParameters, pStandardProcessing, Row, Field)
	vFolioRefLeft = FolioRefLeft;
	vFolioRefRight = FolioRefRight;
	pStandardProcessing = False;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck, Item, DragParameters, Row, Field", "FolioDocumentsLeftDrag", Item, pDragParameters, Row, Field), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Process drag parameters
	If pDragParameters.Value.Count() = 1 Then
		vRef = pDragParameters.Value[0];
		vRefAttr = tcOnServer.cmGetAtributeAsArray(vRef);
		If TypeOf(vRef) = Type("DocumentRef.Payment") Or 
		   TypeOf(vRef) = Type("DocumentRef.Return") Or
		   TypeOf(vRef) = Type("DocumentRef.Preauthorisation") Then
			If vRefAttr.Property("Folio") Then
				vFolioRefRight = vRefAttr.Folio;
			EndIf;
			If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
				pStandardProcessing = True;
				Return;
			EndIf;	
			vFolioRefLeftAttrs = tcOnServer.cmGetAtributeAsArray(vFolioRefLeft);
			vFolioRefRightAttrs = tcOnServer.cmGetAtributeAsArray(vFolioRefRight);
			If vFolioRefLeftAttrs.GuestGroup = vFolioRefRightAttrs.GuestGroup And 
			   vFolioRefLeftAttrs.Customer = vFolioRefRightAttrs.Customer And
			   vFolioRefLeftAttrs.Contract = vFolioRefRightAttrs.Contract And
			   vFolioRefLeftAttrs.Client = vFolioRefRightAttrs.Client And 
			   vFolioRefLeftAttrs.Company = vFolioRefRightAttrs.Company And 
			   vFolioRefLeftAttrs.FolioCurrency = vFolioRefRightAttrs.FolioCurrency And 
			   vFolioRefLeftAttrs.ParentDoc = vFolioRefRightAttrs.ParentDoc And 
			   ValueIsFilled(vRef) Then
				// Just change folio in payment
				ChangePaymentFolio(vRef, vFolioRefLeft);
			Else
				vTransferPayment = vRef;
				vTransferPaymentMethod = PredefinedValue("Catalog.PaymentMethods.DepositTransfer");
				If ValueIsFilled(vTransferPayment) And 
				  (TypeOf(vTransferPayment) = Type("DocumentRef.Payment") Or TypeOf(vTransferPayment) = Type("DocumentRef.Return") Or TypeOf(vTransferPayment) = Type("DocumentRef.DepositTransfer")) Then
					vTransferPaymentMethod = tcOnServer.cmGetAttributeByRef(vTransferPayment, "PaymentMethod");
				Else
					vTransferPayment = Undefined;
				EndIf;
				OpenForm("Document.DepositTransfer.Form.tcDocumentForm", New Structure("Basis, FolioTo, EmployeePINCodeChecked, PaymentMethod, Payment", vFolioRefRight, vFolioRefLeft, True, vTransferPaymentMethod, vTransferPayment), ThisObject, vFolioRefLeft, , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else 
			If vRefAttr.Property("Folio") Then
				vFolioRefRight = vRefAttr.Folio;
			EndIf;
			If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
				pStandardProcessing = True;
				Return;
			EndIf;
			vTransList = New ValueList();
			vTransList.LoadValues(pDragParameters.Value);
			AddNewTransactionToFolio(vTransList, vFolioRefRight, vFolioRefLeft);
		EndIf;	
	ElsIf pDragParameters.Value.Count() > 1 Then 
		vRef = pDragParameters.Value[0];
		vRefAttr = tcOnServer.cmGetAtributeAsArray(vRef);
		If vRefAttr.Property("Folio") Then
			vFolioRefRight = vRefAttr.Folio;
		EndIf;
		If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
			pStandardProcessing = True;
			Return;
		EndIf;
		vTransList = New ValueList();
		vTransList.LoadValues(pDragParameters.Value);
		AddNewTransactionToFolio(vTransList, vFolioRefRight, vFolioRefLeft);
	EndIf;
	Notify("Document.Folio.Edit");
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsRightDrag(Item, pDragParameters, pStandardProcessing, Row, Field)
	vFolioRefLeft = FolioRefLeft;
	vFolioRefRight = FolioRefRight;
	pStandardProcessing = False;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck, Item, DragParameters, Row, Field", "FolioDocumentsRightDrag", Item, pDragParameters, Row, Field), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Process drag parameters
	If pDragParameters.Value.Count() = 1 Then
		vRef = pDragParameters.Value[0];
		vRefAttr = tcOnServer.cmGetAtributeAsArray(vRef);
		If TypeOf(vRef) = Type("DocumentRef.Payment") Or 
		   TypeOf(vRef) = Type("DocumentRef.Return") Or
		   TypeOf(vRef) = Type("DocumentRef.Preauthorisation") Then
			If vRefAttr.Property("Folio") Then
				vFolioRefLeft = vRefAttr.Folio;
			EndIf;
			If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
				pStandardProcessing = True;
				Return;
			EndIf;
			vFolioRefLeftAttrs = tcOnServer.cmGetAtributeAsArray(vFolioRefLeft);
			vFolioRefRightAttrs = tcOnServer.cmGetAtributeAsArray(vFolioRefRight);
			If vFolioRefLeftAttrs.GuestGroup = vFolioRefRightAttrs.GuestGroup And 
			   vFolioRefLeftAttrs.Customer = vFolioRefRightAttrs.Customer And
			   vFolioRefLeftAttrs.Contract = vFolioRefRightAttrs.Contract And
			   vFolioRefLeftAttrs.Client = vFolioRefRightAttrs.Client And 
			   vFolioRefLeftAttrs.Company = vFolioRefRightAttrs.Company And 
			   vFolioRefLeftAttrs.FolioCurrency = vFolioRefRightAttrs.FolioCurrency And 
			   vFolioRefLeftAttrs.ParentDoc = vFolioRefRightAttrs.ParentDoc And 
			   ValueIsFilled(vRef) Then
				// Just change folio in payment
				ChangePaymentFolio(vRef, vFolioRefRight);
			Else
				vTransferPayment = vRef;
				vTransferPaymentMethod = PredefinedValue("Catalog.PaymentMethods.DepositTransfer");
				If ValueIsFilled(vTransferPayment) And 
				  (TypeOf(vTransferPayment) = Type("DocumentRef.Payment") Or TypeOf(vTransferPayment) = Type("DocumentRef.Return") Or TypeOf(vTransferPayment) = Type("DocumentRef.DepositTransfer")) Then
					vTransferPaymentMethod = tcOnServer.cmGetAttributeByRef(vTransferPayment, "PaymentMethod");
				Else
					vTransferPayment = Undefined;
				EndIf;
				OpenForm("Document.DepositTransfer.Form.tcDocumentForm", New Structure("Basis, FolioTo, EmployeePINCodeChecked, PaymentMethod, Payment", vFolioRefLeft, vFolioRefRight, True, vTransferPaymentMethod, vTransferPayment), ThisObject, vFolioRefRight, , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else 
			If vRefAttr.Property("Folio") Then
				vFolioRefLeft = vRefAttr.Folio;
			EndIf;
			If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
				pStandardProcessing = True;
				Return;
			EndIf;
			vTransList = New ValueList();
			vTransList.LoadValues(pDragParameters.Value);
			AddNewTransactionToFolio(vTransList, vFolioRefLeft, vFolioRefRight);
		EndIf;	
	ElsIf pDragParameters.Value.Count() > 1 Then 
		vRef = pDragParameters.Value[0];
		vRefAttr = tcOnServer.cmGetAtributeAsArray(vRef);
		If vRefAttr.Property("Folio") Then
			vFolioRefLeft = vRefAttr.Folio;
		EndIf;
		If vFolioRefRight = vFolioRefLeft Or Not ValueIsFilled(vFolioRefLeft) Or Not ValueIsFilled(vFolioRefRight) Then
			pStandardProcessing = True;
			Return;
		EndIf;
		vTransList = New ValueList();
		vTransList.LoadValues(pDragParameters.Value);
		AddNewTransactionToFolio(vTransList, vFolioRefLeft, vFolioRefRight);
	EndIf;
	Notify("Document.Folio.Edit");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsLeftDragCheck(pItem, pDragParameters, pStandardProcessing, pRow, pField)
	pDragParameters.AllowedActions = DragAllowedActions.Move; 
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsRightDragCheck(pItem, pDragParameters, pStandardProcessing, pRow, pField)
	pDragParameters.AllowedActions = DragAllowedActions.Move; 
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsLeftDragStart(pItem, pDragParameters, pPerform)
	vRefsList = New ValueList();
	i = 0;
	While i < pDragParameters.Value.Count() Do
		vRowData = FolioDocumentsLeft.FindByID(pDragParameters.Value.Get(i));
		If vRowData <> Undefined Then
			vInserted = False;
			vRef = vRowData.Ref;
			If ValueIsFilled(vRef) Then
				If vRefsList.FindByValue(vRef) = Undefined Then
					pDragParameters.Value.Insert(i + 1, vRef);
					vInserted = True;
					vRefsList.Add(vRef);
				EndIf;
			EndIf;
			pDragParameters.Value.Delete(i);
			If vInserted Then
				i = i + 1;
			EndIf;
			// Check child items
			vChildItems = vRowData.GetItems();
			If vChildItems.Count() > 0 Then
				For Each vChildItem In vChildItems Do
					vInserted = False;
					vRef = vChildItem.Ref;
					If ValueIsFilled(vRef) Then
						If vRefsList.FindByValue(vRef) = Undefined Then
							pDragParameters.Value.Insert(i, vRef);
							vInserted = True;
							vRefsList.Add(vRef);
						EndIf;
					EndIf;
					If vInserted Then
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;		
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsRightDragStart(pItem, pDragParameters, pPerform)
	vRefsList = New ValueList();
	i = 0;
	While i < pDragParameters.Value.Count() Do
		vRowData = FolioDocumentsRight.FindByID(pDragParameters.Value.Get(i));
		If vRowData <> Undefined Then
			vInserted = False;
			vRef = vRowData.Ref;
			If ValueIsFilled(vRef) Then
				If vRefsList.FindByValue(vRef) = Undefined Then
					pDragParameters.Value.Insert(i + 1, vRef);
					vInserted = True;
					vRefsList.Add(vRef);
				EndIf;
			EndIf;
			pDragParameters.Value.Delete(i);
			If vInserted Then
				i = i + 1;
			EndIf;
			// Check child items
			vChildItems = vRowData.GetItems();
			If vChildItems.Count() > 0 Then
				For Each vChildItem In vChildItems Do
					vInserted = False;
					vRef = vChildItem.Ref;
					If ValueIsFilled(vRef) Then
						If vRefsList.FindByValue(vRef) = Undefined Then
							pDragParameters.Value.Insert(i, vRef);
							vInserted = True;
							vRefsList.Add(vRef);
						EndIf;
					EndIf;
					If vInserted Then
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;		
EndProcedure

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsLeftOnActivateRow(Item)
	If IsOnActivateRowMode Then
		Return;
	EndIf;
	IsOnActivateRowMode = True;
	CurLeftListTransactionID = Items.FolioDocumentsLeft.CurrentRow;
	vCurPage = "FolioDocumentsLeft";
	If Item.Name = vCurPage Then
		Items.FolioDocumentsRight.SelectedRows.Clear();
		vSelectedRows = Items.FolioDocumentsLeft.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			Items.FolioDocumentsLeftTransfer.Enabled  = True;
			Items.FolioDocumentsRightTransfer.Enabled = False;
			vCurRow = ThisObject[vCurPage].FindByID(vSelectedRows[0]);
			If Not vCurRow = Undefined Then
				InvoiceLeft = vCurRow.Invoice;
				Items.InvoiceLeft.Visible = ValueIsFilled(InvoiceLeft);
				Items.InvoiceLanguageLeft.Visible = ValueIsFilled(InvoiceLeft);
				Items.CreateInvoiceLeft.Visible = Not ValueIsFilled(InvoiceLeft);
				If TypeOf(vCurRow.Ref) = Type("DocumentRef.Preauthorisation") Then
					Items.FolioDocumentsLeftPayment.Title =  NStr("en='Computation';ru='Рассчитать';de='Berechnen'");
				Else
					Items.FolioDocumentsLeftPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
				EndIf;
				InvoiceLanguageLeft = GetInvoiceDefaultLanguage(InvoiceLeft);
			Else
				Items.FolioDocumentsLeftPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
				Items.InvoiceLeft.Visible = False;
				Items.InvoiceLanguageLeft.Visible = False;
				Items.CreateInvoiceLeft.Visible = True;
			EndIf;	
		Else 
			Items.FolioDocumentsLeftTransfer.Enabled  = False;
			Items.FolioDocumentsRightTransfer.Enabled = False;
			Items.FolioDocumentsLeftPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
			Items.InvoiceLeft.Visible = False;
			Items.InvoiceLanguageLeft.Visible = False;
			Items.CreateInvoiceLeft.Visible = True;
		EndIf;	
	Else
		Items.FolioDocumentsLeftTransfer.Enabled  = False;
		Items.FolioDocumentsRightTransfer.Enabled = False;
		Items.InvoiceLeft.Visible = False;
		Items.InvoiceLanguageLeft.Visible = False;
		Items.CreateInvoiceLeft.Visible = True;
	EndIf;
	ControlVisibility(vCurPage);
	IsOnActivateRowMode = False;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsRightOnActivateRow(Item)
	If IsOnActivateRowMode Then
		Return;
	EndIf;
	IsOnActivateRowMode = True;
	CurRightListTransactionID = Items.FolioDocumentsRight.CurrentRow;
	vCurPage = "FolioDocumentsRight";
	If Item.Name = vCurPage Then
		Items.FolioDocumentsLeft.SelectedRows.Clear();
		vSelectedRows = Items.FolioDocumentsRight.SelectedRows;
		If vSelectedRows.Count()>0 Then
			Items.FolioDocumentsLeftTransfer.Enabled  = False;
			Items.FolioDocumentsRightTransfer.Enabled = True;
			vCurRow = ThisObject[vCurPage].FindByID(vSelectedRows[0]);
			If Not vCurRow = Undefined Then
				InvoiceRight = vCurRow.Invoice;
				Items.InvoiceRight.Visible = ValueIsFilled(InvoiceRight);
				Items.InvoiceLanguageRight.Visible = ValueIsFilled(InvoiceRight);
				Items.CreateInvoiceRight.Visible = Not ValueIsFilled(InvoiceRight);
				If TypeOf(vCurRow.Ref) = Type("DocumentRef.Preauthorisation") Then
					Items.FolioDocumentsRightPayment.Title =  NStr("en='Computation';ru='Рассчитать';de='Berechnen'");
				Else
					Items.FolioDocumentsRightPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
				EndIf;	
				InvoiceLanguageRight = GetInvoiceDefaultLanguage(InvoiceRight);
			Else
				Items.FolioDocumentsRightPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
				Items.InvoiceRight.Visible = False;
				Items.InvoiceLanguageRight.Visible = False;
				Items.CreateInvoiceRight.Visible = True;
			EndIf;	
		Else 
			Items.FolioDocumentsLeftTransfer.Enabled  = False;
			Items.FolioDocumentsRightTransfer.Enabled = False;
			Items.FolioDocumentsRightPayment.Title =  NStr("en='Payment';ru='Оплатить';de='Bezahlen'");
			Items.InvoiceRight.Visible = False;
			Items.InvoiceLanguageRight.Visible = False;
			Items.CreateInvoiceRight.Visible = True;
		EndIf;	
	Else
		Items.FolioDocumentsLeftTransfer.Enabled  = False;
		Items.FolioDocumentsRightTransfer.Enabled = False;
		Items.InvoiceRight.Visible = False;
		Items.InvoiceLanguageRight.Visible = False;
		Items.CreateInvoiceRight.Visible = True;
	EndIf;
	ControlVisibility(vCurPage);
	IsOnActivateRowMode = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChargeRight(Command)
	If Not ValueIsFilled(FolioRefRight) Then
		Return;
	EndIf;

	vResult = ChargeAtServer(FolioRefRight);
	If Not vResult = "" Then
		ShowMessageBox(, vResult);
	Else
		// APDEX
		vKeyOperation = "Document.Charge.Form.tcDocumentForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Document.Charge.Form.tcDocumentForm", New Structure("Basis", FolioRefRight), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	Endif;
EndProcedure // ChargeRight

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChargeLeft(Command)
	vResult = ChargeAtServer(FolioRefLeft);
	If Not vResult = "" Then
		ShowMessageBox(, vResult);
	Else
		// APDEX
		vKeyOperation = "Document.Charge.Form.tcDocumentForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Document.Charge.Form.tcDocumentForm", New Structure("Basis", FolioRefLeft), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	Endif;
EndProcedure // ChargeLeft

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PaymentLeft(Command)    
	vCurrRow = Items.FolioDocumentsLeft.CurrentData;
	
	If Not vCurrRow = Undefined And ValueIsFilled(vCurrRow.Ref) And TypeOf(vCurrRow.Ref) = Type("DocumentRef.Preauthorisation") Then  
		OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", vCurrRow.Ref, vCurrRow.Ref), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);  
	Else	
		vNeedSelecPreauthorisation = CheckPreauthorisation(FolioRefLeft);
		
		tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), , "Documents.Payment", , NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
		
		If Not vNeedSelecPreauthorisation Then
			// Build list of selected charges and storno
			vSelectedCharges = New ValueList();
			vCanceledCharges = New ValueList();
			vRows = GetSelectedRows("FolioDocumentsLeft", , True);
			If vRows.Count() > 0 Then
				For Each vStr In vRows Do
					vStrData = FolioDocumentsLeft.FindByID(vStr);
					// Check is it Charge or Storno
					If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Then
						If vCanceledCharges.FindByValue(vStrData.Ref) = Undefined Then
							vSelectedCharges.Add(vStrData.Ref);
							vMergedCharges = GetRoomRateTransactions(vStrData.Ref);
							For Each vMergedCharge In vMergedCharges Do
								If TypeOf(vMergedCharge) = Type("DocumentRef.Storno") Then
									vParentCharge = tcOnServer.cmGetAttributeByRef(vMergedCharge, "ParentCharge");
									vCanceledCharges.Add(vParentCharge);
									vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
									If vCanceledChargeItem <> Undefined Then
										vSelectedCharges.Delete(vCanceledChargeItem);
									EndIf;
								Else
									If vMergedCharge <> vStrData.Ref Then
										If vCanceledCharges.FindByValue(vMergedCharge) = Undefined Then
											vSelectedCharges.Add(vMergedCharge);
										EndIf;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					ElsIf TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Then
						vParentCharge = tcOnServer.cmGetAttributeByRef(vStrData.Ref, "ParentCharge");
						vCanceledCharges.Add(vParentCharge);
						vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
						If vCanceledChargeItem <> Undefined Then
							vSelectedCharges.Delete(vCanceledChargeItem);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			// Create new payment
			If vSelectedCharges.Count() > 0 Then
				OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document, SelectedChargesList", FolioRefLeft, FolioRefLeft, vSelectedCharges), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			Else
				OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", FolioRefLeft, FolioRefLeft), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else        
			vND = New NotifyDescription("Attacheble_AfterQueryBoxPreauthorisation", ThisObject, New Structure("Folio", FolioRefLeft)); 
			vQueryText = NStr("en = 'There are not calculated pre-authorizations, perform the calculation?'; 
						      |de = 'Es liegen keine berechneten Vorautorisierungen vor. Führen Sie die Berechnung durch?'; 
						      |ru = 'Есть нерассчитанные преавторизации, выполнить расчет?'");
			ShowQueryBox(vND, vQueryText, QuestionDialogMode.YesNo); 
		EndIf; 
	EndIf;
EndProcedure // PaymentLeft

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PaymentRight(Command)
	If Not ValueIsFilled(FolioRefRight) Then
		Return;
	EndIf;
	vCurrRow = Items.FolioDocumentsRight.CurrentData;
	
	If Not vCurrRow = Undefined And ValueIsFilled(vCurrRow.Ref) And TypeOf(vCurrRow.Ref) = Type("DocumentRef.Preauthorisation") Then  
		OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", vCurrRow.Ref, vCurrRow.Ref), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);  
	Else
		vNeedSelecPreauthorisation = CheckPreauthorisation(FolioRefRight);
		
		tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), , "Documents.Payment", , NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
		
		If Not vNeedSelecPreauthorisation Then
			// Build list of selected charges and storno
			vSelectedCharges = New ValueList();
			vCanceledCharges = New ValueList();
			vRows = GetSelectedRows("FolioDocumentsRight", , True);
			If vRows.Count() > 0 Then
				For Each vStr In vRows Do
					vStrData = FolioDocumentsRight.FindByID(vStr);
					// Check is it Charge or Storno
					If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Then
						If vCanceledCharges.FindByValue(vStrData.Ref) = Undefined Then
							vSelectedCharges.Add(vStrData.Ref);
							vMergedCharges = GetRoomRateTransactions(vStrData.Ref);
							For Each vMergedCharge In vMergedCharges Do
								If TypeOf(vMergedCharge) = Type("DocumentRef.Storno") Then
									vParentCharge = tcOnServer.cmGetAttributeByRef(vMergedCharge, "ParentCharge");
									vCanceledCharges.Add(vParentCharge);
									vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
									If vCanceledChargeItem <> Undefined Then
										vSelectedCharges.Delete(vCanceledChargeItem);
									EndIf;
								Else
									If vMergedCharge <> vStrData.Ref Then
										If vCanceledCharges.FindByValue(vMergedCharge) = Undefined Then
											vSelectedCharges.Add(vMergedCharge);
										EndIf;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					ElsIf TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Then
						vParentCharge = tcOnServer.cmGetAttributeByRef(vStrData.Ref, "ParentCharge");
						vCanceledCharges.Add(vParentCharge);
						vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
						If vCanceledChargeItem <> Undefined Then
							vSelectedCharges.Delete(vCanceledChargeItem);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			// Create new payment
			If vSelectedCharges.Count() > 0 Then
				OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document, SelectedChargesList", FolioRefLeft, FolioRefLeft, vSelectedCharges), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			Else
				OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", FolioRefRight, FolioRefRight), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else  
			vND = New NotifyDescription("Attacheble_AfterQueryBoxPreauthorisation", ThisObject, New Structure("Folio", FolioRefRight)); 
			vQueryText = NStr("en = 'There are not calculated pre-authorizations, perform the calculation?'; 
						      |de = 'Es liegen keine berechneten Vorautorisierungen vor. Führen Sie die Berechnung durch?'; 
						      |ru = 'Есть нерассчитанные преавторизации, выполнить расчет?'");
			ShowQueryBox(vND, vQueryText, QuestionDialogMode.YesNo); 
		EndIf; 
	EndIf;
EndProcedure // PaymentRight

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PreauthorisationtLeft(Command)
	// Get documents selected
	vCurDoc = GetCurrentDoc("FolioDocumentsLeft");
	If ValueIsFilled(vCurDoc) And TypeOf(vCurDoc) = Type("DocumentRef.Preauthorisation") Then
		vParentDoc = vCurDoc;
	Else
		vParentDoc = FolioRefLeft;
	EndIf;
	// Create new Preauthorisation
	OpenForm("Document.Preauthorisation.Form.tcDocumentForm", New Structure("Basis", vParentDoc), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PreauthorisationtRight(Command)
	// Get documents selected
	vCurDoc = GetCurrentDoc("FolioDocumentsRight");
	If ValueIsFilled(vCurDoc) And TypeOf(vCurDoc) = Type("DocumentRef.Preauthorisation") Then
		vParentDoc = vCurDoc;
	Else
		vParentDoc = FolioRefRight;
	EndIf;
	// Create new Preauthorisation
	OpenForm("Document.Preauthorisation.Form.tcDocumentForm", New Structure("Basis", vParentDoc), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ReturnLeft(Command)
	ReturnPayment("FolioDocumentsLeft");	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ReturnRight(Command)
	If Not ValueIsFilled(FolioRefRight) Then
		Return;
	EndIf;

	ReturnPayment("FolioDocumentsRight");
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure BonusesPaymentLeft(Command)    
	vCurrRow = Items.FolioDocumentsLeft.CurrentData;
	
	// Build list of selected charges and storno
	vSelectedCharges = New ValueList();
	vCanceledCharges = New ValueList();
	vRows = GetSelectedRows("FolioDocumentsLeft", , True);
	If vRows.Count() > 0 Then
		For Each vStr In vRows Do
			vStrData = FolioDocumentsLeft.FindByID(vStr);
			// Check is it Charge or Storno
			If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Then
				If vCanceledCharges.FindByValue(vStrData.Ref) = Undefined Then
					vSelectedCharges.Add(vStrData.Ref);
					vMergedCharges = GetRoomRateTransactions(vStrData.Ref);
					For Each vMergedCharge In vMergedCharges Do
						If TypeOf(vMergedCharge) = Type("DocumentRef.Storno") Then
							vParentCharge = tcOnServer.cmGetAttributeByRef(vMergedCharge, "ParentCharge");
							vCanceledCharges.Add(vParentCharge);
							vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
							If vCanceledChargeItem <> Undefined Then
								vSelectedCharges.Delete(vCanceledChargeItem);
							EndIf;
						Else
							If vMergedCharge <> vStrData.Ref Then
								If vCanceledCharges.FindByValue(vMergedCharge) = Undefined Then
									vSelectedCharges.Add(vMergedCharge);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			ElsIf TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Then
				vParentCharge = tcOnServer.cmGetAttributeByRef(vStrData.Ref, "ParentCharge");
				vCanceledCharges.Add(vParentCharge);
				vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
				If vCanceledChargeItem <> Undefined Then
					vSelectedCharges.Delete(vCanceledChargeItem);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Create new bonuses payment
	If vSelectedCharges.Count() > 0 Then
		OpenForm("Document.BonusesPayment.Form.tcDocumentForm", New Structure("Basis, SelectedChargesList", FolioRefLeft, vSelectedCharges), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	Else
		OpenForm("Document.BonusesPayment.Form.tcDocumentForm", New Structure("Basis", FolioRefLeft), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure // BonusesPaymentLeft

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure BonusesPaymentRight(Command)    
	vCurrRow = Items.FolioDocumentsRight.CurrentData;
	
	// Build list of selected charges and storno
	vSelectedCharges = New ValueList();
	vCanceledCharges = New ValueList();
	vRows = GetSelectedRows("FolioDocumentsRight", , True);
	If vRows.Count() > 0 Then
		For Each vStr In vRows Do
			vStrData = FolioDocumentsRight.FindByID(vStr);
			// Check is it Charge or Storno
			If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Then
				If vCanceledCharges.FindByValue(vStrData.Ref) = Undefined Then
					vSelectedCharges.Add(vStrData.Ref);
					vMergedCharges = GetRoomRateTransactions(vStrData.Ref);
					For Each vMergedCharge In vMergedCharges Do
						If TypeOf(vMergedCharge) = Type("DocumentRef.Storno") Then
							vParentCharge = tcOnServer.cmGetAttributeByRef(vMergedCharge, "ParentCharge");
							vCanceledCharges.Add(vParentCharge);
							vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
							If vCanceledChargeItem <> Undefined Then
								vSelectedCharges.Delete(vCanceledChargeItem);
							EndIf;
						Else
							If vMergedCharge <> vStrData.Ref Then
								If vCanceledCharges.FindByValue(vMergedCharge) = Undefined Then
									vSelectedCharges.Add(vMergedCharge);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			ElsIf TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Then
				vParentCharge = tcOnServer.cmGetAttributeByRef(vStrData.Ref, "ParentCharge");
				vCanceledCharges.Add(vParentCharge);
				vCanceledChargeItem = vSelectedCharges.FindByValue(vParentCharge);
				If vCanceledChargeItem <> Undefined Then
					vSelectedCharges.Delete(vCanceledChargeItem);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Create new bonuses payment
	If vSelectedCharges.Count() > 0 Then
		OpenForm("Document.BonusesPayment.Form.tcDocumentForm", New Structure("Basis, SelectedChargesList", FolioRefRight, vSelectedCharges), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	Else
		OpenForm("Document.BonusesPayment.Form.tcDocumentForm", New Structure("Basis", FolioRefRight), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure // BonusesPaymentRight

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure StornoLeft(Command)
	ClearMessages();
	If Not ValueIsFilled(FolioRefLeft) Then
		Return;
	EndIf;
	vPage = "FolioDocumentsLeft";
	vAllowedListStorno = GetAllowedChargeForReversal(vPage);
	If CheckUserPermissionsForStorno(FolioRefLeft) And vAllowedListStorno.Count() > 0 Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "StornoLeft"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		EmployeePINCodeChecked = False;
		
		vLabelDescription = NStr("en='Choose type of reversal...';ru='Укажите тип сторно...';de='Geben Sie den Stornotyp an...'");
		vFolio = FolioRefLeft;
		
		vParametersStructure = New Structure("Page, Folio, ListStorno", vPage, vFolio, vAllowedListStorno);
		vNotifity = New NotifyDescription("AfterInputCancelActionType", ThisObject, vParametersStructure);
		OpenForm("CommonForm.tcInputCancelActionType", New Structure("LabelDescription", vLabelDescription), ThisObject, , , , vNotifity, FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure StornoRight(Command)
	ClearMessages();
	If Not ValueIsFilled(FolioRefRight) Then
		Return;
	EndIf;
	vPage = "FolioDocumentsRight";
	vAllowedListStorno = GetAllowedChargeForReversal(vPage);
	If CheckUserPermissionsForStorno(FolioRefRight) And vAllowedListStorno.Count() > 0 Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "StornoRight"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		
		vLabelDescription = NStr("en='Choose type of reversal...';ru='Укажите тип сторно...';de='Geben Sie den Stornotyp an...'");
		vFolio = FolioRefRight;
		
		vParametersStructure = New Structure("Page, Folio, ListStorno", vPage, vFolio, vAllowedListStorno);
		vNotifity = New NotifyDescription("AfterInputCancelActionType", ThisObject, vParametersStructure);
		OpenForm("CommonForm.tcInputCancelActionType", New Structure("LabelDescription", vLabelDescription), ThisObject, , , , vNotifity, FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure TransferLeft(Command)
	If Not ValueIsFilled(FolioRefLeft) Then
		Return;
	EndIf;
	// Do transfer
	If Not Items.FolioDocumentsLeftTransfer.Check Then
		vMessage = "";
		If Not TransferAtServer(FolioRefLeft, "FolioDocumentsLeft", amClipboard, vMessage) Then
			ShowMessageBox(, vMessage);
			Return;
		EndIf;
		If amClipboard.Property("TransferTransactionsType") Then
			Items.FolioDocumentsLeftTransfer.Check = True;
			Items.FolioDocumentsLeftTransfer1.Check = True;
			Items.FolioDocumentsRightTransfer.Check = False;
			Items.FolioDocumentsRightTransfer1.Check = False;
		EndIf;
		// Notify for transfer operation start other folio transactions forms
		Notify("TransferOperation.Start", FolioRefLeft, ThisObject);
	Else
		Items.FolioDocumentsLeftTransfer.Check = False;
		Items.FolioDocumentsLeftTransfer1.Check = False;
		// Clear clipboard
		amClipboard.Delete("TransferTransactionsType");
		amClipboard.Delete("TransferTransactions");
		amClipboard.Delete("TransferFolioFrom");
		TClipboardContent = "";
		// Notify transfer end
		Notify("TransferOperation.End", FolioRefLeft, ThisObject);
		Notify("TransferOperation.End", FolioRefRight, ThisObject);
	EndIf;
	ControlVisibility();
EndProcedure // TransferLeft

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure TransferRight(Command)
	If Not ValueIsFilled(FolioRefRight) Then
		Return;
	EndIf;
	// Do transfer
	If Not Items.FolioDocumentsRightTransfer.Check Then
		vMessage = "";
		If Not TransferAtServer(FolioRefRight, "FolioDocumentsRight", amClipboard, vMessage) Then
			ShowMessageBox(, vMessage);
			Return;
		EndIf;	
		If amClipboard.Property("TransferTransactionsType") Then
			Items.FolioDocumentsRightTransfer.Check = True;
			Items.FolioDocumentsRightTransfer1.Check = True;
			Items.FolioDocumentsLeftTransfer.Check = False;
			Items.FolioDocumentsLeftTransfer1.Check = False;
		EndIf;
		// Notify for transfer operation start other folio transactions forms
		Notify("TransferOperation.Start", FolioRefRight, ThisObject);
	Else
		Items.FolioDocumentsRightTransfer.Check = False;
		Items.FolioDocumentsRightTransfer1.Check = False;
		// Clear clipboard
		amClipboard.Delete("TransferTransactionsType");
		amClipboard.Delete("TransferTransactions");
		amClipboard.Delete("TransferFolioFrom");
		TClipboardContent = "";
		// Notify transfer end
		Notify("TransferOperation.End", FolioRefRight, ThisObject);
		Notify("TransferOperation.End", FolioRefLeft, ThisObject);
	EndIf;
	ControlVisibility();
EndProcedure // TransferRight

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PasteLeft(Command)
	vMessage = "";
	vTransferTransactionsType = Undefined;
	If amClipboard <> Undefined Then
		If amClipboard.Property("TransferTransactionsType", vTransferTransactionsType) Then
			If vTransferTransactionsType = "ChargeTransfer" Or vTransferTransactionsType = "PreauthorisationTransfer" Then
				// Check user PIN if necessary
				If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
					OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "PasteLeft"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
					Return;
				EndIf;
				EmployeePINCodeChecked = False;
			EndIf;
		EndIf;
		vOpenDepositTransfer = False;
		If Not PasteAtServer(FolioRefLeft, amClipboard, vMessage, vOpenDepositTransfer) Then
			ShowMessageBox(, vMessage);
			Return;
		Else
			If vOpenDepositTransfer Then
				vFolioFrom = FolioRefRight;
				If amClipboard.Property("TransferFolioFrom") And ValueIsFilled(amClipboard.TransferFolioFrom) Then
					vFolioFrom = amClipboard.TransferFolioFrom;
				EndIf;
				vTransferPayment = Undefined;
				vTransferPaymentMethod = Undefined;
				vTransferTransactions = Undefined;
				If amClipboard.Property("TransferTransactions", vTransferTransactions) Then
					If vTransferTransactions.Count() = 1 Then
						vTransferPayment = vTransferTransactions.Get(0).Value;
						If ValueIsFilled(vTransferPayment) And 
						  (TypeOf(vTransferPayment) = Type("DocumentRef.Payment") Or TypeOf(vTransferPayment) = Type("DocumentRef.Return") Or TypeOf(vTransferPayment) = Type("DocumentRef.DepositTransfer")) Then
							vTransferPaymentMethod = tcOnServer.cmGetAttributeByRef(vTransferPayment, "PaymentMethod");
						Else
							vTransferPayment = Undefined;
						EndIf;
					EndIf;
				EndIf;
				OpenForm("Document.DepositTransfer.Form.tcDocumentForm", New Structure("Basis, FolioTo, EmployeePINCodeChecked, PaymentMethod, Payment", vFolioFrom, FolioRefLeft, True, vTransferPaymentMethod, vTransferPayment), ThisObject, FolioRefLeft, , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		EndIf;
		// Clear clipboard
		amClipboard.Delete("TransferTransactionsType");
		amClipboard.Delete("TransferTransactions");
		amClipboard.Delete("TransferFolioFrom");
		TClipboardContent = "";
		// Notify transfer end
		Notify("TransferOperation.End", FolioRefLeft, ThisObject);
		Notify("TransferOperation.End", FolioRefRight, ThisObject);
	EndIf;
	UpdatePanelsOnServer(False, False, False);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PasteRight(Command)
	vMessage = "";
	vTransferTransactionsType = Undefined;
	If amClipboard <> Undefined Then
		If amClipboard.Property("TransferTransactionsType", vTransferTransactionsType) Then
			If vTransferTransactionsType = "ChargeTransfer" Or vTransferTransactionsType = "PreauthorisationTransfer" Then
				// Check user PIN if necessary
				If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
					OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "PasteRight"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
					Return;
				EndIf;
				EmployeePINCodeChecked = False;
			EndIf;
		EndIf;
		vOpenDepositTransfer = False;
		If Not PasteAtServer(FolioRefRight, amClipboard, vMessage, vOpenDepositTransfer) Then
			ShowMessageBox(, vMessage);
			Return;
		Else
			If vOpenDepositTransfer Then
				vFolioFrom = FolioRefLeft;
				If amClipboard.Property("TransferFolioFrom") And ValueIsFilled(amClipboard.TransferFolioFrom) Then
					vFolioFrom = amClipboard.TransferFolioFrom;
				EndIf;
				vTransferPayment = Undefined;
				vTransferPaymentMethod = Undefined;
				vTransferTransactions = Undefined;
				If amClipboard.Property("TransferTransactions", vTransferTransactions) Then
					If vTransferTransactions.Count() = 1 Then
						vTransferPayment = vTransferTransactions.Get(0).Value;
						If ValueIsFilled(vTransferPayment) And 
						  (TypeOf(vTransferPayment) = Type("DocumentRef.Payment") Or TypeOf(vTransferPayment) = Type("DocumentRef.Return") Or TypeOf(vTransferPayment) = Type("DocumentRef.DepositTransfer")) Then
							vTransferPaymentMethod = tcOnServer.cmGetAttributeByRef(vTransferPayment, "PaymentMethod");
						Else
							vTransferPayment = Undefined;
						EndIf;
					EndIf;
				EndIf;
				OpenForm("Document.DepositTransfer.Form.tcDocumentForm", New Structure("Basis, FolioTo, EmployeePINCodeChecked, PaymentMethod, Payment", vFolioFrom, FolioRefRight, True, vTransferPaymentMethod, vTransferPayment), ThisObject, FolioRefRight, , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		EndIf;
		// Clear clipboard
		amClipboard.Delete("TransferTransactionsType");
		amClipboard.Delete("TransferTransactions");
		amClipboard.Delete("TransferFolioFrom");
		TClipboardContent = "";
		// Notify transfer end
		Notify("TransferOperation.End", FolioRefRight, ThisObject);
		Notify("TransferOperation.End", FolioRefLeft, ThisObject);
	EndIf;
	UpdatePanelsOnServer(False, False, False);
EndProcedure

 // ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioAdd(Command)
	OpenForm("Document.Folio.ObjectForm", New Structure("ParentObj", ObjectRef), , , , , New NotifyDescription("AfterCloseFolioForm", ThisObject), FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CheckOut(Command)
	AccList = New ValueList();
	vCurFolio = FolioRefLeft;
	vCurAccDoc = tcOnServer.cmGetAttributeByRef(vCurFolio, "ParentDoc");
	// Edit accommodation and fill group table from the given list
	If ValueIsFilled(vCurAccDoc) And TypeOf(vCurAccDoc) = Type("DocumentRef.Accommodation") Then
		// Check if this document was already processed
		If AccList.FindByValue(vCurAccDoc) = Undefined Then
			AccList.Add(vCurAccDoc);
			AddOneRoomAccommodations(AccList, vCurAccDoc, True, True);
		EndIf;
	EndIf;	
	If AccList.Count() > 0 Then
		vCurAccDoc = AccList.Get(AccList.Count() - 1).Value;
		MainRoomDoc = GetMainDocRef(vCurAccDoc);
		// Give warning if current date is less then expected check-out date
		vCheckInDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckInDate");
		vExpectedCheckOutDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckOutDate");
		If BegOfDay(vExpectedCheckOutDate) > BegOfDay(CurrentDate()) Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				                                            |de='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				                                            |ru='Дата планируемого выезда " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"));
		EndIf;
		// Get check-out date
		CheckOutDateTime = '00010101';
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
			GetCheckOutDate(vCheckInDate, vExpectedCheckOutDate);
		Else
			CheckOutDateTime = vExpectedCheckOutDate;
		EndIf;
		AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
	EndIf;
EndProcedure // CheckOut

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateProformaInvoiceLeft(pCommand)
	If ValueIsFilled(FolioRefLeft) Then 
		OpenForm("CommonForm.tcNewInvoiceForm", New Structure("ParentDoc", FolioRefLeft));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Folio is not selected!'; ru='Лицевой счет не выбран!'; de='Folio ist nicht ausgewählt!'"));
	EndIf;
EndProcedure // CreateProformaInvoiceLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateProformaInvoiceRight(pCommand)
	If ValueIsFilled(FolioRefRight) Then
		OpenForm("CommonForm.tcNewInvoiceForm", New Structure("ParentDoc", FolioRefRight));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Folio is not selected!'; ru='Лицевой счет не выбран!'; de='Folio ist nicht ausgewählt!'"));
	EndIf;
EndProcedure // CreateProformaInvoiceRight

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostingsLeft(pCommand)
	If Not ValueIsFilled(FolioRefLeft) Then
		ShowMessageBox(, NStr("ru='Не выбран лицевой счет!';
		                      |de='Kein Folio ausgewählt!'; 
		                      |en='No folio selected!'"));
		Return;
	EndIf;
	#IF NOT MobileClient THEN
		OpenForm("CommonForm.tcDirectPostingsForm", New Structure("Folio", FolioRefLeft), , FolioRefLeft);
	#ELSE
		OpenForm("CommonForm.mcDirectPostingsForm", New Structure("Folio", FolioRefLeft), , FolioRefLeft);	
	#ENDIF
EndProcedure // ShowDirectPostingsLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostingsRight(pCommand)
	If Not ValueIsFilled(FolioRefRight) Then
		ShowMessageBox(, NStr("ru='Не выбран лицевой счет!';
		                      |de='Kein Folio ausgewählt!'; 
		                      |en='No folio selected!'"));
		Return;
	EndIf;
	#IF NOT MobileClient THEN
		OpenForm("CommonForm.tcDirectPostingsForm", New Structure("Folio", FolioRefRight), , FolioRefRight);
	#ELSE
		OpenForm("CommonForm.mcDirectPostingsForm", New Structure("Folio", FolioRefRight), , FolioRefRight);	
	#ENDIF
EndProcedure // ShowDirectPostingsRight

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectingRows(pCommand)
	vName = "";
	vDocsList = Undefined;
	If pCommand.Name = "SelectTransactionsByServiceLeft" Then
		vName = "Left"; 
		Items.FolioDocumentsLeft.SelectedRows.Clear();
		vDocsList = FolioDocumentsLeft;
	ElsIf pCommand.Name = "SelectTransactionsByServiceRight" Then
		vName = "Right";
		Items.FolioDocumentsLeft.SelectedRows.Clear();
		vDocsList = FolioDocumentsRight;
	EndIf;
	For Each vDocsListRow In vDocsList.GetItems() Do
		vDocsListRow.IsChecked = False;
		For Each vChildDocsListRow In vDocsListRow.GetItems() Do
			vChildDocsListRow.IsChecked = False;
		EndDo;
	EndDo;
	vServiceList = GetServiceList(vName);
	If vServiceList.Count() > 0 Then
		vServiceList.ShowCheckItems( New NotifyDescription("AfterCheckService", ThisObject, vName), NStr("en = 'Selected service'; de = 'Ausgewählter Dienst'; ru = 'Выберите услуги'"));	
	EndIf;
EndProcedure // SelectingRows

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectTransactions(pCommand)
	If pCommand.Name = "SelectTransactionsLeft" Then
		vTransactions = FolioDocumentsLeft;
		vTransactionsList = Items.FolioDocumentsLeft;
		vSelectTransactionsButton = Items.FolioDocumentsLeftSelectTransactionsLeft;
		vIsCheckedColumn = Items.FolioDocumentsLeftIsChecked;
	Else
		vTransactions = FolioDocumentsRight;
		vTransactionsList = Items.FolioDocumentsRight;
		vSelectTransactionsButton = Items.FolioDocumentsRightSelectTransactionsRight;
		vIsCheckedColumn = Items.FolioDocumentsRightIsChecked;
	EndIf;
		
	vSelectTransactionsButton.Check = Not vSelectTransactionsButton.Check;
	If vSelectTransactionsButton.Check Then
		vIsCheckedColumn.Visible = True;
	Else
		vIsCheckedColumn.Visible = False;
		vTransactionsList.SelectedRows.Clear();
		For Each vRowData In vTransactions.GetItems() Do
			vRowData.IsChecked = False;
			If vRowData.GetItems().Count() > 0 Then
				For Each vChildRowData In vRowData.GetItems() Do
					vChildRowData.IsChecked = False;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SelectTransactions

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateInvoiceLeft(pCommand)
	// Get selected transactions
	vSelectedRows = Undefined;
	vNumberOfSelectedFirstLevelRows = GetNumberOfSelectedFirstLevelRows("FolioDocumentsLeft");
	If vNumberOfSelectedFirstLevelRows <> 1 Then
		vSelectedRows = GetSelectedRows("FolioDocumentsLeft");
		If vSelectedRows.Count() <= 1 Then
			vSelectedRows = Undefined;
		EndIf;
	EndIf;
	// Check date and ask for invoice date if invoice is created later then check-out date
	vActionParams = UPPER(tcOnServer.cmGetAttributeByRef(PredefinedValue("Catalog.ObjectFormActions.FolioFillSettlement"), "Parameter"));
	vParams = New Structure("Folio, SelectedRows, TransactionListName", FolioRefLeft, vSelectedRows, "FolioDocumentsLeft");
	vInvoiceDate = '00010101';
	vCurDate = BegOfDay(CurrentDate());
	vCheckInDate = BegOfDay(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "DateTimeFrom"));
	vCheckOutDate = BegOfDay(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "DateTimeTo"));
	If ValueIsFilled(vCheckOutDate) And vCurDate > vCheckOutDate Or StrFind(vActionParams, "ASK_FOR_DATE") > 0 Then
		// Ask user to select invoice date
		vInvoiceDate = EndOfDay(vCheckOutDate);
		If vInvoiceDate > EndOfDay(vCurDate) Then
			vInvoiceDate = EndOfDay(vCheckInDate);
		EndIf;			
		ShowInputDate(New NotifyDescription("CreateInvoiceAtClient", ThisObject, vParams), vInvoiceDate, NStr("en='Select invoice date please!'; ru='Укажите дату акта!'; de='Bitte Rechnungsdatum auswählen!'"), DateFractions.Date);
	Else
		// Create invoice by current date
		CreateInvoiceAtClient(vInvoiceDate, vParams);
	EndIf;
EndProcedure // CreateInvoiceLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateInvoiceRight(pCommand)
	// Get selected transactions
	vSelectedRows = Undefined;
	vNumberOfSelectedFirstLevelRows = GetNumberOfSelectedFirstLevelRows("FolioDocumentsRight");
	If vNumberOfSelectedFirstLevelRows <> 1 Then
		vSelectedRows = GetSelectedRows("FolioDocumentsRight");
		If vSelectedRows.Count() <= 1 Then
			vSelectedRows = Undefined;
		EndIf;
	EndIf;
	// Check date and ask for invoice date if invoice is created later then check-out date
	vActionParams = UPPER(tcOnServer.cmGetAttributeByRef(PredefinedValue("Catalog.ObjectFormActions.FolioFillSettlement"), "Parameter"));
	vParams = New Structure("Folio, SelectedRows, TransactionListName", FolioRefRight, vSelectedRows, "FolioDocumentsRight");
	vInvoiceDate = '00010101';
	vCurDate = BegOfDay(CurrentDate());
	vCheckInDate = BegOfDay(tcOnServer.cmGetAttributeByRef(FolioRefRight, "DateTimeFrom"));
	vCheckOutDate = BegOfDay(tcOnServer.cmGetAttributeByRef(FolioRefRight, "DateTimeTo"));
	If ValueIsFilled(vCheckOutDate) And vCurDate > vCheckOutDate Or StrFind(vActionParams, "ASK_FOR_DATE") > 0 Then
		// Ask user to select invoice date
		vInvoiceDate = EndOfDay(vCheckOutDate);
		If vInvoiceDate > EndOfDay(vCurDate) Then
			vInvoiceDate = EndOfDay(vCheckInDate);
		EndIf;			
		ShowInputDate(New NotifyDescription("CreateInvoiceAtClient", ThisObject, vParams), vInvoiceDate, NStr("en='Select invoice date please!'; ru='Укажите дату акта!'; de='Bitte Rechnungsdatum auswählen!'"), DateFractions.Date);
	Else
		// Create invoice by current date
		CreateInvoiceAtClient(vInvoiceDate, vParams);
	EndIf;
EndProcedure // CreateInvoiceRight

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure Print(Command)
	vName = "";
	vPosLeft = StrFind(Command.Name, "FolioDocumentsLeft");
	vPosRight = StrFind(Command.Name, "FolioDocumentsRight");
	
	If vPosLeft > 0 Then
		vName = Mid(Command.Name, vPosLeft + 18);
		vCurFolio = FolioRefLeft;
		vPage = "FolioDocumentsLeft";
	ElsIf vPosRight > 0 Then
		vName = Mid(Command.Name, vPosRight + 19);
		vCurFolio = FolioRefRight;
		vPage = "FolioDocumentsRight";
	EndIf;	
	
	If vCurFolio.IsEmpty() Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Unknown document'; ru = 'Не указан документ'; de = 'Unbekannte Dokument'"));
		Return;
	EndIf;	
	
	vPrintFormTypeRef = GetPrintFormTypeRef(vName,Command.Name);
	vPrintFormTypeArray = tcOnServer.cmGetAtributeAsArray(vPrintFormTypeRef);
	
	vTransactions = new Array;
	vNumberOfSelectedFirstLevelRows = GetNumberOfSelectedFirstLevelRows(vPage);
	vRows = GetSelectedRows(vPage);
	If vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintChargeRu") Or
	   vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintChargeEn") Or
	   vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintChargeDe") Then
		For Each vStr In vRows Do
			vStrData = ThisObject[vPage].FindByID(vStr);
			If ValueIsFilled(vStrData.Ref) Then
				vTransactions.Add(vStrData.Ref);
			EndIf;
	    EndDo;
	Else
		If vRows.Count() > 1 Then
			If vNumberOfSelectedFirstLevelRows <> 1 Then
				GetSelectedTransactions(vPage, vRows, vTransactions);
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(vPrintFormTypeArray.ExternalProcessing) Then
		Try
			OpenExternalProcedureForm(vPrintFormTypeArray.ExternalProcessing, vPrintFormTypeRef, vCurFolio, vTransactions);						
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'")+Chars.LF+ErrorDescription());                                                                                                                                       
		EndTry;
	ElsIf ValueIsFilled(vPrintFormTypeArray.Report) Then
		Try
			OpenExternalReportForm(vPrintFormTypeArray.Report, vPrintFormTypeRef, vCurFolio, vTransactions);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
		EndTry;
	ElsIf vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges") Then
		vPrintFormSettings = GetReceiptPrintSettings(vPrintFormTypeRef);
		
		vFirstDoc = Undefined;
		If vTransactions.Count() = 0 Then
			For Each vStr In vRows Do
				vStrData = ThisObject[vPage].FindByID(vStr);
				vTransactions.Add(vStrData.Ref);
				If vFirstDoc = Undefined Then
					vFirstDoc = vStrData.Ref;
				EndIf;
			EndDo;
		Else
			vFirstDoc = vTransactions.Get(0);
		EndIf;
		If vFirstDoc <> Undefined Then
			vFolio = tcOnServer.cmGetAttributeByRef(vFirstDoc, "Folio");
			vLanguage = GetLanguageByFolio(vFolio);
			PrintReceipt(vFolio, vLanguage, vTransactions, vPrintFormSettings);
		EndIf;
	ElsIf vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintPKOByPayment") Then
		For Each vStr In vRows Do
			vStrData = ThisObject[vPage].FindByID(vStr);
			If ValueIsFilled(vStrData.Ref) And TypeOf(vStrData.Ref) = Type("DocumentRef.Payment") Then
				vTransactions.Add(vStrData.Ref);
			EndIf;
	    EndDo;
		If vTransactions.Count() > 0 Then
			vParams = New Structure("InputParameter, ObjectPrintingForm, Transactions", vCurFolio, vPrintFormTypeRef, vTransactions);
			OpenForm("Document.Folio.Form.tcFolioPrintPKO", vParams, ThisObject, New UUID);
		Else
			ShowMessageBox(, NStr("en = 'No payment is selected!'; ru = 'Не выбран платеж!'; de = 'Kein Personenkonto ist gewählt!'"));
		EndIf;
	Else
		vParams = New Structure("InputParameter, ObjectPrintingForm, Transactions", vCurFolio, vPrintFormTypeRef, vTransactions);
		OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisObject, New UUID);
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure RefreshPages(Command)
	UpdatePanelsOnServer(True, False, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SendOnlineChequeLeft(pCommand)
	vCurData = Items.FolioDocumentsLeft.CurrentData;
	SendOnlineCheque(vCurData);
EndProcedure // SendOnlineChequeLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure SendOnlineChequeRight(Command)
	vCurData = Items.FolioDocumentsRight.CurrentData;
	SendOnlineCheque(vCurData);
EndProcedure // SendOnlineChequeRight

// -----------------------------------------------------------------------------
&AtClient
Procedure MakeKeyLeft(pCommand)
	MakeKey(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "ParentDoc"));
EndProcedure // MakeKeyLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure MakeKeyRight(pCommand)
	MakeKey(tcOnServer.cmGetAttributeByRef(FolioRefRight, "ParentDoc"));
EndProcedure // MakeKeyRight

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueIdentityCardLeft(pCommand)
	IssueIdentityCard(FolioRefLeft);
EndProcedure // IssueIdentityCardLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueIdentityCardRight(pCommand)
	IssueIdentityCard(FolioRefRight);
EndProcedure // IssueIdentityCardRight

// -----------------------------------------------------------------------------
&AtClient
Procedure AdvanceSettlementChequeLeft(pCommand)
	// Create new payment
	tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), , "Documents.Payment", , NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
	OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document, AdditionalProperties", FolioRefLeft, FolioRefLeft, New Structure("AdvanceSettlementMode", True)), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure // AdvanceSettlementChequeLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure AdvanceSettlementChequeRight(pCommand)
	// Create new payment
	tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"),, "Documents.Payment", , NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
	OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document, AdditionalProperties", FolioRefRight, FolioRefRight, New Structure("AdvanceSettlementMode", True)), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure // AdvanceSettlementChequeRight

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceLeft(pCommand, pInvoice = Undefined)
	vInvoice = Undefined;
	If pInvoice = Undefined Then 
		// Get posted invoices for the folio
		vInvList = GetListOfFolioInvoices(FolioRefLeft);
		If vInvList.Count() = 0 Then
			vMessage = NStr("en='No invoices found for the folio selected!';ru='По выбранному лицевому счету нет актов (счетов)!';de='Auf dem gewählten persönlichen Konto gibt es keine (Proforma-)Rechnungen!'");
			ShowMessageBox(, vMessage);
		ElsIf vInvList.Count() = 1 Then
			vInvoice = vInvList.Get(0).Value;
		Else
			ShowChooseFromMenu(New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisObject), vInvList, Items.FolioDocumentsLeft);
		EndIf;
	Else
		vInvoice = pInvoice;
	EndIf;
	If ValueIsFilled(vInvoice) Then
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // InvoiceLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceRight(pCommand, pInvoice = Undefined)
	vInvoice = Undefined;
	If pInvoice = Undefined Then 
		// Get posted invoices for the folio
		vInvList = GetListOfFolioInvoices(FolioRefRight);
		If vInvList.Count() = 0 Then
			vMessage = NStr("en='No invoices found for the folio selected!';ru='По выбранному лицевому счету нет актов (счетов)!';de='Auf dem gewählten persönlichen Konto gibt es keine (Proforma-)Rechnungen!'");
			ShowMessageBox(, vMessage);
		ElsIf vInvList.Count() = 1 Then
			vInvoice = vInvList.Get(0).Value;
		Else
			ShowChooseFromMenu(New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisObject), vInvList, Items.FolioDocumentsLeft);
		EndIf;
	Else
		vInvoice = pInvoice;
	EndIf;
	If ValueIsFilled(vInvoice) Then
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // InvoiceRight

// -----------------------------------------------------------------------------
&AtClient
Procedure CorrectionLeft(pCommand)
	Correction(FolioRefLeft, "FolioDocumentsLeft", "CorrectionLeft");
EndProcedure // CorrectionLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure CorrectionRight(pCommand)
	Correction(FolioRefRight, "FolioDocumentsRight", "CorrectionRight");
EndProcedure // CorrectionRight

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitLeft(pCommand)
	Split(FolioRefLeft, "FolioDocumentsLeft", "SplitLeft");
EndProcedure // SplitLeft

// -----------------------------------------------------------------------------  
&AtClient
Procedure BindToAccommodationLeft(pCommand)
	BindToAccommodation(FolioRefLeft, "FolioDocumentsLeft", "BindToAccommodationLeft");
EndProcedure // BindToAccommodationLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitRight(pCommand)
	Split(FolioRefRight, "FolioDocumentsRight", "SplitRight");
EndProcedure // SplitRight

// -----------------------------------------------------------------------------  
&AtClient
Procedure BindToAccommodationRight(pCommand)
	BindToAccommodation(FolioRefRight, "FolioDocumentsRight", "BindToAccommodationRight");
EndProcedure // BindToAccommodationRight

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeButtonStatusLeft(pCommand)  
	vNameButton = pCommand.Name; 
	vButtonArr = StrSplit("CurrentGuestFoliosLeft,AccompanyGuestLeft,MasterFoliosLeft,GuestGroupsFoliosLeft", ",");
	If vNameButton = "AccompanyGuestLeft" Then
		For Each vGuestRow In SelectedAccompanyGuestsLeft Do
			vGuestRow.Balance = 0;
			vGuestRow.BalanceCurrency = Undefined;
		EndDo;
		For Each vRow In FoliosTypes Do
			If vRow.Client <> MainGuest And vRow.Type = 0 Then
				vGuestRow = Undefined;
				vGuestRows = SelectedAccompanyGuestsLeft.FindRows(New Structure("Client", vRow.Client));
				If vGuestRows.Count() = 0 Then
					vGuestRow = SelectedAccompanyGuestsLeft.Add();
					vGuestRow.Client = vRow.Client;
					vGuestRow.AccommodationType = vRow.AccommodationType;
					vGuestRow.CheckInDate = vRow.CheckInDate;
					vGuestRow.Duration = vRow.Duration;
					vGuestRow.CheckOutDate = vRow.CheckOutDate;
					vGuestRow.Balance = vRow.Balance;
					vGuestRow.BalanceCurrency = vRow.FolioCurrency;
				Else
					vGuestRow = vGuestRows.Get(0);
					If Not ValueIsFilled(vGuestRow.BalanceCurrency) Then
						vGuestRow.BalanceCurrency = vRow.FolioCurrency;
					EndIf;
					vGuestRow.Balance = vGuestRow.Balance + tcOnServer.ConvertCurrencies(vRow.Balance, vRow.FolioCurrency, , vGuestRow.BalanceCurrency, , CurrentDate());
				EndIf;
			EndIf;	
		EndDo;  
		If SelectedAccompanyGuestsLeft.Count() = 1 Then 
			Items[vNameButton].Check = True;
			Items[vNameButton].ShapeRepresentation = ButtonShapeRepresentation.Auto; 
			For Each vBtn In vButtonArr Do
				If vNameButton <> vBtn Then
					Items[vBtn].Check = False;	
					Items[vBtn].ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
				EndIf;	
			EndDo;  
			SelectedAccompanyGuestsLeft[0].Check = True;
			FolioPageTypeLeft = 1;   
			UpdatePanelsOnServer(False, True, False);
		ElsIf SelectedAccompanyGuestsLeft.Count() > 1 Then 
			vSharedGuests = New Array();
			For Each vGuestRow In SelectedAccompanyGuestsLeft Do
				vSharedGuests.Add(New Structure("Check, Client, AccommodationType, CheckInDate, Duration, CheckOutDate, Balance, BalanceCurrency", vGuestRow.Check, vGuestRow.Client, vGuestRow.AccommodationType, vGuestRow.CheckInDate, vGuestRow.Duration, vGuestRow.CheckOutDate, vGuestRow.Balance, vGuestRow.BalanceCurrency));
			EndDo;
			OpenForm("CommonForm.tcSharedGuestsSelectionForm", New Structure("SharedGuests, FoliosPage", vSharedGuests, "Left"), ThisObject, MainGuest, , , , FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	ElsIf vNameButton = "MasterFoliosLeft" Then
		FolioPageTypeLeft = 2;
	ElsIf vNameButton = "GuestGroupsFoliosLeft" Then
		FolioPageTypeLeft = 3;
	Else
		FolioPageTypeLeft = 0; // CurrentGuestFoliosLeft
	EndIf;	
	If Not vNameButton = "AccompanyGuestLeft" Then   
		Items[vNameButton].Check = True;
		Items[vNameButton].ShapeRepresentation = ButtonShapeRepresentation.Auto; 
		For Each vBtn In vButtonArr Do
			If vNameButton <> vBtn Then
				Items[vBtn].Check = False;	
				Items[vBtn].ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
			EndIf;	
		EndDo;  
		UpdatePanelsOnServer(False, True, False);         
	EndIf;   
EndProcedure // ChangeButtonStatusLeft

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeButtonStatusRight(pCommand)  
	vNameButton = pCommand.Name; 
	vButtonArr = StrSplit("CurrentGuestFoliosRight,AccompanyGuestRight,MasterFoliosRight,GuestGroupsFoliosRight", ",");
	If vNameButton = "AccompanyGuestRight" Then 
		For Each vGuestRow In SelectedAccompanyGuestsRight Do
			vGuestRow.Balance = 0;
			vGuestRow.BalanceCurrency = Undefined;
		EndDo;
		For Each vRow In FoliosTypes Do
			If vRow.Client <> MainGuest And vRow.Type = 0 Then
				vGuestRow = Undefined;
				vGuestRows = SelectedAccompanyGuestsRight.FindRows(New Structure("Client", vRow.Client));
				If vGuestRows.Count() = 0 Then
					vGuestRow = SelectedAccompanyGuestsRight.Add();
					vGuestRow.Client = vRow.Client;
					vGuestRow.AccommodationType = vRow.AccommodationType;
					vGuestRow.CheckInDate = vRow.CheckInDate;
					vGuestRow.Duration = vRow.Duration;
					vGuestRow.CheckOutDate = vRow.CheckOutDate;
					vGuestRow.Balance = vRow.Balance;
					vGuestRow.BalanceCurrency = vRow.FolioCurrency;
				Else
					vGuestRow = vGuestRows.Get(0);
					If Not ValueIsFilled(vGuestRow.BalanceCurrency) Then
						vGuestRow.BalanceCurrency = vRow.FolioCurrency;
					EndIf;
					vGuestRow.Balance = vGuestRow.Balance + tcOnServer.ConvertCurrencies(vRow.Balance, vRow.FolioCurrency, , vGuestRow.BalanceCurrency, , CurrentDate());
				EndIf;
			EndIf;	
		EndDo;  
		If SelectedAccompanyGuestsRight.Count() = 1 Then 
			Items[vNameButton].Check = True;
			Items[vNameButton].ShapeRepresentation = ButtonShapeRepresentation.Auto; 
			For Each vBtn In vButtonArr Do
				If vNameButton <> vBtn Then
					Items[vBtn].Check = False;	
					Items[vBtn].ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
				EndIf;	
			EndDo;  
			SelectedAccompanyGuestsRight[0].Check = True;
			FolioPageTypeRight = 1;   
			UpdatePanelsOnServer(False, False, True);
		ElsIf SelectedAccompanyGuestsRight.Count() > 1 Then 
			vSharedGuests = New Array();
			For Each vGuestRow In SelectedAccompanyGuestsRight Do
				vSharedGuests.Add(New Structure("Check, Client, AccommodationType, CheckInDate, Duration, CheckOutDate, Balance, BalanceCurrency", vGuestRow.Check, vGuestRow.Client, vGuestRow.AccommodationType, vGuestRow.CheckInDate, vGuestRow.Duration, vGuestRow.CheckOutDate, vGuestRow.Balance, vGuestRow.BalanceCurrency));
			EndDo;
			OpenForm("CommonForm.tcSharedGuestsSelectionForm", New Structure("SharedGuests, FoliosPage", vSharedGuests, "Right"), ThisObject, MainGuest, , , , FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	ElsIf vNameButton = "MasterFoliosRight" Then
		FolioPageTypeRight = 2;
	ElsIf vNameButton = "GuestGroupsFoliosRight" Then
		FolioPageTypeRight = 3;
	Else
		FolioPageTypeRight = 0; // CurrentGuestFoliosLeft
	EndIf;	
	If Not vNameButton = "AccompanyGuestRight" Then   
		Items[vNameButton].Check = True;
		Items[vNameButton].ShapeRepresentation = ButtonShapeRepresentation.Auto; 
		For Each vBtn In vButtonArr Do
			If vNameButton <> vBtn Then
				Items[vBtn].Check = False;	
				Items[vBtn].ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
			EndIf;	
		EndDo;  
		UpdatePanelsOnServer(False, False, True);         
	EndIf;   
EndProcedure // ChangeButtonStatusRight

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenActs(pCommand)
	
	vGuestGroup = tcOnServer.cmGetAttributeByRef(ObjectRef, "GuestGroup");
	
	vParameters = New Structure();
	
	vParameters.Insert("SelGuestGroup", vGuestGroup);	
	
	OpenForm("Document.Settlement.ListForm", vParameters);
		
EndProcedure // OpenActs

#EndRegion

#Region Private
			   
// ------------------------------------------------------------------------------------------------
&AtServer
Procedure UpdatePanelsOnServer(pRefreshList = False, pResetFolioLeft = True, pResetFolioRight = True) 
	vDocumentsArray = GetDocumentsArray();
	GetFolios(vDocumentsArray, pRefreshList);
	FillFolioFilter();
	FillPresentationFoliosList("FolioDocumentsLeft", pResetFolioLeft); 
	FillLeftPanelHeader(FolioRefLeft);  
	FillFolioPage(FolioRefLeft, "FolioDocumentsLeft"); 
	If Split Then
		FillPresentationFoliosList("FolioDocumentsRight", pResetFolioRight);  
		FillRightPanelHeader(FolioRefRight);   
		FillFolioPage(FolioRefRight, "FolioDocumentsRight"); 
	EndIf;	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChargeServiceByBarcode(pMarkingCode)   
	If IsBlankString(pMarkingCode) Then
		Return;
	EndIf;	
	vService = Undefined;   
	vErr = "";  
	vBarcode = ""; 
	vMarkingCode = pMarkingCode;  
	vHotel = tcOnServer.cmGetAttributeByRef(FolioRefLeft,"Hotel");
	If StrLen(pMarkingCode)> 13 Then // it's datamatrix code   
		// Convert string to base64 string	
		vMS = New MemoryStream;
		vTxt = New TextWriter(vMS) ;
		vTxt.Write(pMarkingCode);
		vTxt.Close();
		vBD = vMS.CloseAndGetBinaryData();
		vMarkingCode = Base64String(vBD);   

		vUseCharge = CheckMarkingCode(vMarkingCode); 
		If ValueIsFilled(vUseCharge) Then
			ShowMessageBox(, StrTemplate(Nstr("en = 'There is already an accrual with this marking code
                                              |%1'; de = 'Mit diesem Markierungscode besteht bereits eine Rückstellung
                                              |%1'; ru = 'Уже есть начисление с таким кодом маркировки 
                                              |%1'"), vUseCharge), , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	   
			Return;
		EndIf;	
		If StrLen(pMarkingCode) = 29 Then // it's cigarettes 
        	vBarcode = Mid(pMarkingCode, 2, 13); 
		ElsIf StrLen(pMarkingCode) = 20 Then // it's fur coats 
			vBarcode = pMarkingCode;  
		Else
			vBarcode = Mid(pMarkingCode, 4, 13);
		EndIf;	
		vService = GetService(vBarcode, vHotel);
	Else // usual barcode	   
		vService = GetService(pMarkingCode, vHotel);
	EndIf;	  
	If IsBlankString(vBarcode) Then
		vBarcode = pMarkingCode;
	EndIf;	
	If ValueIsFilled(vService) Then     
		vRef = Undefined;
		If Not ChargeServiceByBarcodeOnServer(vService, vMarkingCode, vErr, vRef) Then
			ShowMessageBox(, vErr, , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	
		Else
			ShowUserNotification(Nstr("en = 'Service accrued'; de = 'Dienst aufgelaufen'; ru = 'Начислена услуга'"), GetURL(vRef), vService);
		EndIf;
	Else     
		vTxt = StrTemplate(Nstr("en = 'Service with barcode %1 not found!'; 
								|de = 'Service mit Barcode %1 nicht gefunden!'; 
								|ru = 'Услуга с штрихкодом %1 не найдена!
                                	|Выберите услугу из списка после закрытия окна с ошибкой'"), vBarcode);
		ShowMessageBox(New NotifyDescription("ChooseServiceAndCreateCharge", ThisObject, New Structure("MarkingCode", vMarkingCode)), vTxt, , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	
	EndIf;     
EndProcedure // ChargeServiceByBarcode

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function CheckMarkingCode(pMarkingCode)
	vQuery = New Query;
	vQuery.Text = "SELECT
	|	Charge.Ref AS Ref,
	|	Storno.Ref AS Storno
	|FROM
	|	Document.Charge AS Charge
	|		LEFT JOIN Document.Storno AS Storno
	|		ON (Storno.ParentCharge = Charge.Ref)
	|WHERE
	|	Charge.MarkingCode = &qMarkingCode
	|	AND Charge.DeletionMark = FALSE
	|	AND Charge.Posted = TRUE
	|	AND Storno.Number IS NULL";
	
	vQuery.SetParameter("qMarkingCode", pMarkingCode);
	
	vQueryResult = vQuery.Execute();
	If vQueryResult.IsEmpty() Then
		Return Undefined;
	Else	
		vRes = vQueryResult.Select();
		vRes.Next();
		Return vRes.Ref;
	EndIf;
EndFunction // CheckMarkingCode

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChooseServiceAndCreateCharge(pAdditionalParameters) Export
	// APDEX
	vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	vFormParam = New Structure("Hotel, ClientType, AccountingDate, MultipleChoice, UseMarking", tcOnServer.cmGetAttributeByRef(FolioRefLeft,"Hotel"), Undefined, CurrentDate(), False, StrLen(pAdditionalParameters.MarkingCode)> 13);
	OpenForm("Catalog.Services.ChoiceForm", vFormParam, , , , , New NotifyDescription("ChooseServiceAndCreateChargeContinue", ThisObject, pAdditionalParameters),  FormWindowOpeningMode.LockWholeInterface);
EndProcedure // ChooseServiceAndCreateCharge

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChooseServiceAndCreateChargeContinue(pService, pAdditionalParameters) Export
	If pService <> Undefined And ValueIsFilled(pService) Then 
		vErr = "";    
		vRef = Undefined;
		If Not ChargeServiceByBarcodeOnServer(pService, pAdditionalParameters.MarkingCode, vErr, vRef) Then
			ShowMessageBox(, vErr, , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));  
		Else
			ShowUserNotification(Nstr("en = 'Service accrued'; de = 'Dienst aufgelaufen'; ru = 'Начислена услуга'"), GetURL(vRef), pService);	
		EndIf;	
	
	EndIf;	
EndProcedure // ChooseServiceAndCreateChargeContinue

// ------------------------------------------------------------------------------------------------
&AtServer
Function ChargeServiceByBarcodeOnServer(pService, pMarkingCode, pError = "", pNewCharge = Undefined)
	vDoc = Documents.Charge.CreateDocument();
	vDoc.Hotel = FolioRefLeft.Hotel; 
	vDoc.Fill(FolioRefLeft);    
	If StrLen(pMarkingCode) > 13 Then
		vDoc.MarkingCode = pMarkingCode; 
	EndIf;
	vDoc.Service = pService; 
	vPriceStruct = GetServicePrice(vDoc.Service, vDoc.Date, vDoc.Hotel, vDoc.ClientType);
	If vPriceStruct <> Undefined Then
		vDoc.VATRate = vPriceStruct.VATRate;
		vDoc.Price = vPriceStruct.Price;
		If vDoc.Quantity <= 0 Then
			vDoc.Quantity = 1;
		EndIf;
		vDoc.Sum = Round(vDoc.Price * vDoc.Quantity, 2);
		vDoc.VATRate = ?(vDoc.Company.IsUsingSimpleTaxSystem, vDoc.Company.VATRate, vPriceStruct.VATRate);
	Else
		vDoc.VATRate = vDoc.Company.VATRate;
	EndIf;

	Try
		vDoc.Write(DocumentWriteMode.Posting); 
		pNewCharge = vDoc.Ref;
	Except
		vErr = ErrorInfo();   
		pError = BriefErrorDescription(vErr);
		Return False;
	EndTry;
	UpdatePanelsOnServer(True, False, False);
	Return True;
EndFunction // ChargeServiceByBarcodeOnServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetServicePrice(pService, pDate = Undefined, pHotel, pClientType)
	vDate = pDate;
	If pDate = Undefined then
		vDate = CurrentSessionDate();
	EndIf;
	vPrices = cmGetServicePrice(pService, pHotel, vDate, pClientType);
	If vPrices.Count() > 0 Then
		vPriceStruc = New Structure;
		vPriceStruc.Insert("Price", vPrices[0].Price);
		vPriceStruc.Insert("Currency", vPrices[0].Currency);
		vPriceStruc.Insert("VATRate", vPrices[0].VATRate);
		Return vPriceStruc;
	EndIf;
	Return Undefined;
EndFunction // GetServicePrice

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetService(pBarCode, pHotel)
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	T1.Ref AS Ref,
	|	T1.SortCode AS SortCode
	|FROM
	|	(SELECT
	|		Services.Ref AS Ref,
	|		1 AS SortCode
	|	FROM
	|		Catalog.Services AS Services
	|	WHERE
	|		NOT Services.IsFolder
	|		AND NOT Services.DeletionMark
	|		AND Services.BarCode = &qBarCode
	|		AND Services.Hotel = &qHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Services.Ref,
	|		2
	|	FROM
	|		Catalog.Services AS Services
	|	WHERE
	|		NOT Services.IsFolder
	|		AND NOT Services.DeletionMark
	|		AND Services.BarCode = &qBarCode
	|		AND Services.Hotel = VALUE(Catalog.Hotels.EmptyRef)) AS T1
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qBarCode", pBarCode);
	vQry.SetParameter("qHotel", pHotel);
	vServices = vQry.Execute(); 
	If vServices.IsEmpty() Then
		Return Undefined;
	Else
		vService = vServices.Select();
		vService.Next();
		Return vService.Ref;
	EndIf;	
EndFunction // GetService()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillFolioFilter()  
	vObject = ObjectRef;
	If ValueIsFilled(MainGuest) Then
		vObject = MainGuest;
	EndIf;	 
	If TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then
		Items.CurrentGuestFoliosLeft.Visible = True;  
		vAccQty = 0;  
		vBalance = 0; 
		vFolioCurrency = Undefined; 
		vClientsRows = FoliosTypes.FindRows(New Structure("Type", 0));
		For Each vMFRow In vClientsRows Do
			vAccQty = vAccQty + 1;
			vBalance = vBalance + vMFRow.Balance; 
			vFolioCurrency = vMFRow.FolioCurrency; 
		EndDo;  
		If vAccQty > 0 Then     
			vSum = tcOnServer.FormatSum(vBalance, vFolioCurrency, "NFD=2; NZ=0.00; NG=3,0");
			vTmp = NStr("en = 'By documents (%1) %2'; de = 'Nach Dokumenten (%1) %2'; ru = 'По документам (%1) %2'");
			Items.CurrentGuestFoliosLeft.Title = StrTemplate(vTmp, vAccQty, vSum);  
			If Split Then       
				Items.CurrentGuestFoliosRight.Visible = True;
				Items.CurrentGuestFoliosRight.Title = StrTemplate(vTmp, vAccQty, vSum);	
			EndIf;	
		Else
			Items.CurrentGuestFoliosLeft.Visible = False;	
			If Split Then
				Items.CurrentGuestFoliosRight.Visible = False;	
			EndIf;
		EndIf;
	Else	
		vBalance = 0; 
		vFolioCurrency = Undefined; 
		vClientsRows = FoliosTypes.FindRows(New Structure("Type", 0));
		For Each vMFRow In vClientsRows Do
			If ValueIsFilled(MainGuest) And vMFRow.Client <> MainGuest Then
				Continue;
			EndIf;
			vBalance = vBalance + vMFRow.Balance; 
			vFolioCurrency = vMFRow.FolioCurrency;
		EndDo; 
		vSum = tcOnServer.FormatSum(vBalance, vFolioCurrency, "NFD=2; NZ=0.00; NG=3,0");
		// Main guest
		vTitle = StrTemplate("%1 %2" ,String(vObject), vSum) ;
		Items.CurrentGuestFoliosLeft.Title = vTitle;  
		Items.CurrentGuestFoliosLeft.Visible = True; 
		If Split Then
			Items.CurrentGuestFoliosRight.Title = vTitle;  
			Items.CurrentGuestFoliosRight.Visible = True;	
		EndIf;
	EndIf;
	// Fill accompany guest    
	If ValueIsFilled(MainGuest) Then
		vAccQty = 0;  
		vBalance = 0; 
		vFolioCurrency = Undefined; 
		vClientsRows = FoliosTypes.FindRows(New Structure("Type", 0));
		vAccGuests = New Array;
		For Each vMFRow In vClientsRows Do  
			vCurClient =  vMFRow.Client;
			If vCurClient <> MainGuest Then
				If vAccGuests.Find(vCurClient) = Undefined Then 
					vAccQty = vAccQty + 1;
					vAccGuests.Add(vCurClient);
				EndIf;
				vBalance = vBalance + vMFRow.Balance; 
				vFolioCurrency = vMFRow.FolioCurrency; 
			EndIf;	
		EndDo;  
		If vAccQty > 0 Then     
			vSum = tcOnServer.FormatSum(vBalance, vFolioCurrency, "NFD=2; NZ=0.00; NG=3,0");
			If vAccQty = 1 Then
				vTitle = StrTemplate("%1 %2" ,String(vAccGuests[0]), vSum) ;
			Else	
				vTmp = NStr("en = 'Together (%1) %2'; de = 'Zusammen (%1) %2'; ru = 'Совместные (%1) %2'");
				vTitle = StrTemplate(vTmp, vAccQty, vSum);
			EndIf;
			
			Items.AccompanyGuestLeft.Visible = True;
			Items.AccompanyGuestLeft.Title = vTitle;  
			If Split Then       
				Items.AccompanyGuestRight.Visible = True;
				Items.AccompanyGuestRight.Title = vTitle;	
			EndIf;	
		Else
			Items.AccompanyGuestLeft.Visible = False;	
			If Split Then
				Items.AccompanyGuestRight.Visible = False;	
			EndIf;
		EndIf;
	Else
		Items.AccompanyGuestLeft.Visible = False;
		If Split Then
			Items.AccompanyGuestRight.Visible = False;	
		EndIf;
	EndIf;
	// Fill master folios  
	vMasterFolios = FoliosTypes.FindRows(New Structure("Type", 3));  
	vMFQty = 0;  
	vMFBalance = 0; 
	For Each vMFRow In vMasterFolios Do
		vMFQty = vMFQty + 1;
		vMFBalance = vMFBalance + vMFRow.Balance; 
		vFolioCurrency = vMFRow.FolioCurrency;
	EndDo; 
	If vMFQty > 0 Then     
		vSum = tcOnServer.FormatSum(vMFBalance, vFolioCurrency, "NFD=2; NZ=0.00; NG=3,0");
		vTmp = NStr("en = 'Master folios (%1) %2'; de = 'Kontostamm (%1) %2'; ru = 'Постоянные счета (%1) %2'");
		Items.MasterFoliosLeft.Visible = True;
		Items.MasterFoliosLeft.Title = StrTemplate(vTmp, vMFQty, vSum);  
		If Split Then
			Items.MasterFoliosRight.Visible = True;
			Items.MasterFoliosRight.Title = StrTemplate(vTmp, vMFQty, vSum); 
		EndIf;	
	Else
		Items.MasterFoliosLeft.Visible = False;	 
		If Split Then
			Items.MasterFoliosRight.Visible = False;
		EndIf;
	EndIf; 
	// Fill folio groups  
	vGroupFolios = FoliosTypes.FindRows(New Structure("Type", 1));  
	vGFQty = 0;  
	vGFBalance = 0; 
	For Each vMFRow In vGroupFolios Do
		vGFQty = vGFQty + 1;
		vGFBalance = vGFBalance + vMFRow.Balance;  
		vFolioCurrency = vMFRow.FolioCurrency;
	EndDo; 
	If vGFQty > 0 Then     
		vSum = tcOnServer.FormatSum(vGFBalance, vFolioCurrency, "NFD=2; NZ=0.00; NG=3,0");
		vTmp = NStr("en = 'Group folios (%1) %2'; de = 'Gruppenfolio (%1) %2'; ru = 'Счета группы (%1) %2'");
		Items.GuestGroupsFoliosLeft.Visible = True;			
		Items.GuestGroupsFoliosLeft.Title = StrTemplate(vTmp, vGFQty, vSum);  
		If Split Then
			Items.GuestGroupsFoliosRight.Visible = True;
			Items.GuestGroupsFoliosRight.Title = StrTemplate(vTmp, vGFQty, vSum); 
		EndIf;	
	Else
		Items.GuestGroupsFoliosLeft.Visible = False;
		If Split Then
			Items.GuestGroupsFoliosRight.Visible = False;
		EndIf;
	EndIf;  
	If FolioPageTypeLeft <> 0 And
		Items.AccompanyGuestLeft.Visible = False And
		Items.MasterFoliosLeft.Visible = False And
		Items.GuestGroupsFoliosLeft.Visible = False Then
		If TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then  
			FolioPageTypeLeft = 3;
		ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Clients") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.Customers") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.Contracts") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.RoomQuotas") Then
			FolioPageTypeLeft = 2;
		Else
			FolioPageTypeLeft = 0;
		EndIf;
	EndIf;	
	If Split And FolioPageTypeRight <> 0 And
		Items.AccompanyGuestRight.Visible = False And
		Items.MasterFoliosRight.Visible = False And
		Items.GuestGroupsFoliosRight.Visible = False Then
		If TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then  
			FolioPageTypeRight = 3;
		ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Clients") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.Customers") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.Contracts") Or 
		      TypeOf(ObjectRef) = Type("CatalogRef.RoomQuotas") Then
			FolioPageTypeRight = 2;
		Else
			FolioPageTypeRight = 0;
		EndIf;
	EndIf;
	Items.CurrentGuestFoliosLeft.Check = False; 
	Items.CurrentGuestFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
	Items.AccompanyGuestLeft.Check = False;  
	Items.AccompanyGuestLeft.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
	Items.MasterFoliosLeft.Check = False;    
	Items.MasterFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
	Items.GuestGroupsFoliosLeft.Check = False;   
	Items.GuestGroupsFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
	If FolioPageTypeLeft = 0 Then
		Items.CurrentGuestFoliosLeft.Check = True; 
		Items.CurrentGuestFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.Auto;
	ElsIf FolioPageTypeLeft = 1 Then
		Items.AccompanyGuestLeft.Check = True;
		Items.AccompanyGuestLeft.ShapeRepresentation = ButtonShapeRepresentation.Auto;
	ElsIf FolioPageTypeLeft = 2 Then
		Items.MasterFoliosLeft.Check = True;  
		Items.MasterFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.Auto;
	ElsIf FolioPageTypeLeft = 3 Then  
		Items.GuestGroupsFoliosLeft.Check = True;  
		Items.GuestGroupsFoliosLeft.ShapeRepresentation = ButtonShapeRepresentation.Auto;
	EndIf;
	If Split Then
		Items.CurrentGuestFoliosRight.Check = False; 
		Items.CurrentGuestFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
		Items.AccompanyGuestRight.Check = False;  
		Items.AccompanyGuestRight.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
		Items.MasterFoliosRight.Check = False;    
		Items.MasterFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
		Items.GuestGroupsFoliosRight.Check = False;   
		Items.GuestGroupsFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
		If FolioPageTypeRight = 0 Then
			Items.CurrentGuestFoliosRight.Check = True; 
			Items.CurrentGuestFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.Auto;
		ElsIf FolioPageTypeRight = 1 Then
			Items.AccompanyGuestRight.Check = True;
			Items.AccompanyGuestRight.ShapeRepresentation = ButtonShapeRepresentation.Auto;
		ElsIf FolioPageTypeRight = 2 Then
			Items.MasterFoliosRight.Check = True;  
			Items.MasterFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.Auto;
		ElsIf FolioPageTypeRight = 3 Then  
			Items.GuestGroupsFoliosRight.Check = True;  
			Items.GuestGroupsFoliosRight.ShapeRepresentation = ButtonShapeRepresentation.Auto;
		EndIf;
	EndIf;	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure GetFolios(pRefArray = Undefined, pRefreshList = False)
	vShowExtrasFoliosFirst = False;
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vShowExtrasFoliosFirst = vHotel.ShowExtrasFoliosFirst;
	EndIf;
	vShowAllGroupFolios = False;
	If cmCheckUserPermissions("IfFoliosListIsOpenedFromGroupItemThenShowReservationFoliosToo") Then
		vShowAllGroupFolios = True;
	EndIf;
	vClientsList = New ValueList();
	vCustomersList = New ValueList();
	If pRefArray <> Undefined Then
		For Each pRefArrayItem In pRefArray Do
			vClient = Undefined;
			vCustomer = Undefined;
			vAgent = Undefined;
			vRef = Undefined;
			If TypeOf(pRefArrayItem) = Type("ValueListItem") Then
				vRef = pRefArrayItem.Value;
			Else
				vRef = pRefArrayItem;
			EndIf;
			If TypeOf(vRef) = Type("CatalogRef.Clients") Then
				vClient = vRef;
			ElsIf TypeOf(vRef) = Type("DocumentRef.Reservation") Or TypeOf(vRef) = Type("DocumentRef.Accommodation") Then
				If ValueIsFilled(vRef.Guest) Then
					vClient = vRef.Guest;
				EndIf;
				If ValueIsFilled(vRef.Customer) Then
					vCustomer = vRef.Customer;
				EndIf;
				If ValueIsFilled(vRef.Agent) Then
					vAgent = vRef.Agent;
				EndIf;
			ElsIf TypeOf(vRef) = Type("DocumentRef.ResourceReservation") Then
				If ValueIsFilled(vRef.Client) Then
					vClient = vRef.Client;
				EndIf;
				If ValueIsFilled(vRef.Customer) Then
					vCustomer = vRef.Customer;
				EndIf;
				If ValueIsFilled(vRef.Agent) Then
					vAgent = vRef.Agent;
				EndIf;
			EndIf;
			If ValueIsFilled(vClient) Then
				If vClientsList.FindByValue(vClient) = Undefined Then
					vClientsList.Add(vClient);
				EndIf;
			EndIf;
			If ValueIsFilled(vCustomer) Then
				If vCustomersList.FindByValue(vCustomer) = Undefined Then
					vCustomersList.Add(vCustomer);
				EndIf;
				If vCustomersList.FindByValue(vAgent) = Undefined Then
					vCustomersList.Add(vAgent);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	vQry = New Query;
	If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or
	   TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Or
	   TypeOf(ObjectRef) = Type("DocumentRef.ResourceReservation") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS ChargingFolio
		|INTO ParentDocFolios
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.ParentDoc IN(&qRefArray)
		|	AND Folios.ParentDoc <> UNDEFINED
		|	AND NOT Folios.IsArchived
		|	AND NOT Folios.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationCRs.ChargingFolio AS ChargingFolio
		|INTO ReservationFolios
		|FROM
		|	Document.Reservation.ChargingRules AS ReservationCRs
		|WHERE
		|	ReservationCRs.Ref IN(&qRefArray)
		|	AND NOT ReservationCRs.ChargingFolio.IsArchived
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccommodationCRs.ChargingFolio AS ChargingFolio
		|INTO AccommodationFolios
		|FROM
		|	Document.Accommodation.ChargingRules AS AccommodationCRs
		|WHERE
		|	AccommodationCRs.Ref IN(&qRefArray)
		|	AND NOT AccommodationCRs.ChargingFolio.IsArchived
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ResourceReservations.ChargingFolio AS ChargingFolio
		|INTO ResourceReservationFolios
		|FROM
		|	Document.ResourceReservation AS ResourceReservations
		|WHERE
		|	ResourceReservations.Ref IN(&qRefArray)
		|	AND NOT ResourceReservations.ChargingFolio.IsArchived
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GuestGroupFolios.Ref AS ChargingFolio
		|INTO GuestGroupFolios
		|FROM
		|	Document.Folio AS GuestGroupFolios
		|WHERE
		|	GuestGroupFolios.GuestGroup = &qGuestGroup
		|	AND GuestGroupFolios.ParentDoc.Number IS NULL
		|	AND GuestGroupFolios.Hotel = &qHotel
		|	AND NOT GuestGroupFolios.IsArchived
		|	AND NOT GuestGroupFolios.DeletionMark
		|	AND GuestGroupFolios.IsMaster = FALSE
		|	AND GuestGroupFolios.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GuestGroupChargingRules.ChargingFolio AS ChargingFolio
		|INTO GuestGroupChargingRules
		|FROM
		|	Catalog.GuestGroups.ChargingRules AS GuestGroupChargingRules
		|WHERE
		|	GuestGroupChargingRules.Ref = &qGuestGroup
		|	AND GuestGroupChargingRules.ChargingFolio.Hotel = &qHotel
		|	AND NOT GuestGroupChargingRules.ChargingFolio.IsArchived
		|	AND NOT GuestGroupChargingRules.ChargingFolio.DeletionMark
		|	AND GuestGroupChargingRules.ChargingFolio.IsMaster = FALSE
		|	AND GuestGroupChargingRules.Ref <> VALUE(Catalog.GuestGroups.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	NestedSelect.Folio AS Folio
		|INTO MasterFolios
		|FROM
		|	(SELECT DISTINCT
		|		ClientFolios.Ref AS Folio
		|	FROM
		|		Document.Folio AS ClientFolios
		|	WHERE
		|		ClientFolios.Client IN(&qClientsArray)
		|		AND ClientFolios.Customer.Code IS NULL
		|		AND ClientFolios.ParentDoc.Number IS NULL
		|		AND ClientFolios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|		AND (ClientFolios.Company = &qCompany
		|				OR ClientFolios.Company = VALUE(Catalog.Companies.EmptyRef))
		|		AND (ClientFolios.Hotel = &qHotel
		|				OR ClientFolios.IsMaster)
		|		AND NOT ClientFolios.IsClosed
		|		AND NOT ClientFolios.IsArchived
		|		AND NOT ClientFolios.DeletionMark
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		CustomerFolios.Ref
		|	FROM
		|		Document.Folio AS CustomerFolios
		|	WHERE
		|		CustomerFolios.Customer IN(&qCustomersArray)
		|		AND CustomerFolios.ParentDoc.Number IS NULL
		|		AND CustomerFolios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|		AND (CustomerFolios.Company = &qCompany
		|				OR CustomerFolios.Company = VALUE(Catalog.Companies.EmptyRef))
		|		AND (CustomerFolios.Hotel = &qHotel
		|				OR CustomerFolios.IsMaster)
		|		AND NOT CustomerFolios.IsClosed
		|		AND NOT CustomerFolios.IsArchived
		|		AND NOT CustomerFolios.DeletionMark
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		CltFoliosWithBalances.Folio
		|	FROM
		|		AccumulationRegister.Accounts.Balance(
		|				,
		|				(Folio.Client IN (&qClientsArray)
		|					OR Folio.Customer.IsIndividual
		|						AND Folio.Customer <> Hotel.IndividualsCustomer
		|						AND Folio.Customer IN (&qCustomersArray))
		|					AND (Folio.ParentDoc.Number IS NULL
		|							AND Folio.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|							AND NOT Folio.IsClosed
		|						OR NOT Folio.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|							AND NOT Folio.ParentDoc.Number IS NULL
		|							AND NOT Folio.ParentDoc IN (&qRefArray))
		|					AND NOT Folio.IsArchived
		|					AND NOT Folio.DeletionMark
		|					AND (Folio.Company = &qCompany
		|						OR Folio.Company = VALUE(Catalog.Companies.EmptyRef)
		|						OR Folio.Hotel = &qHotel)
		|					AND (Folio.Customer.IsIndividual
		|						AND Folio.Customer <> Hotel.IndividualsCustomer
		|						AND Folio.Customer IN (&qCustomersArray))) AS CltFoliosWithBalances) AS NestedSelect
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FoliosOnScreen.Ref AS Ref
		|INTO FoliosOnScreen
		|FROM
		|	Document.Folio AS FoliosOnScreen
		|WHERE
		|	FoliosOnScreen.Ref IN(&qFoliosOnScreenList)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Folios.ChargingFolio AS Ref,
		|	Folios.Type AS Type
		|INTO Folios
		|FROM
		|	(SELECT
		|		ParentDocFolios.ChargingFolio AS ChargingFolio,
		|		0 AS Type
		|	FROM
		|		ParentDocFolios AS ParentDocFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationFolios.ChargingFolio,
		|		0
		|	FROM
		|		ReservationFolios AS ReservationFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccommodationFolios.ChargingFolio,
		|		0
		|	FROM
		|		AccommodationFolios AS AccommodationFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ResourceReservationFolios.ChargingFolio,
		|		0
		|	FROM
		|		ResourceReservationFolios AS ResourceReservationFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GuestGroupFolios.ChargingFolio,
		|		1
		|	FROM
		|		GuestGroupFolios AS GuestGroupFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GuestGroupChargingRules.ChargingFolio,
		|		1
		|	FROM
		|		GuestGroupChargingRules AS GuestGroupChargingRules
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FoliosOnScreen.Ref,
		|		CASE
		|			WHEN FoliosOnScreen.Ref.ParentDoc IN (&qRefArray)
		|				THEN 0
		|			WHEN FoliosOnScreen.Ref.ParentDoc.Number IS NULL
		|					AND NOT FoliosOnScreen.Ref.GuestGroup.Code IS NULL
		|				THEN 1
		|			WHEN FoliosOnScreen.Ref.ParentDoc.Number IS NULL
		|				THEN 3
		|			ELSE 0
		|		END
		|	FROM
		|		FoliosOnScreen AS FoliosOnScreen
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MasterFolios.Folio,
		|		3
		|	FROM
		|		MasterFolios AS MasterFolios) AS Folios
		|WHERE
		|	NOT Folios.ChargingFolio.DeletionMark
		|
		|GROUP BY
		|	Folios.ChargingFolio,
		|	Folios.Type
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance,
		|	AccountsBalance.Folio AS Folio
		|INTO FolioBalances
		|FROM
		|	AccumulationRegister.Accounts.Balance(
		|			,
		|			Folio IN
		|				(SELECT
		|					Folios.Ref AS Ref
		|				FROM
		|					Folios AS Folios)) AS AccountsBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Folios.Ref AS Ref,
		|	Folios.Type AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.Ref.ParentDoc AS ParentDoc,
		|	Folios.Ref.ParentDoc.Date AS ParentDocDate,
		|	Folios.Ref.Number AS Number,
		|	Folios.Ref.Date AS Date,
		|	Folios.Ref.Client AS Client,
		|	Folios.Ref.DateTimeFrom AS DateTimeFrom,
		|	Folios.Ref.DateTimeTo AS DateTimeTo,
		|	Folios.Ref.Customer AS Customer,
		|	Folios.Ref.Contract AS Contract,
		|	Folios.Ref.Remarks AS Remarks,
		|	Folios.Ref.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.Ref.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.Ref.ParentDoc.Duration AS Duration,
		|	Folios.Ref.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.Ref.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.Balance, 0) AS Balance,
		|	ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Folios AS Folios
		|		LEFT JOIN FolioBalances AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|
		|ORDER BY
		|	Folios.Type,
		|	CASE
		|		WHEN Folios.Ref.ParentDoc.Number IS NULL
		|			THEN 1
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN Folios.Ref.Customer.IsIndividual IS NULL
		|			THEN 0
		|		WHEN Folios.Ref.Customer.IsIndividual
		|			THEN 0
		|		ELSE 1
		|	END,
		|	Folios.Ref.ParentDoc.PointInTime,
		|	CASE
		|		WHEN Folios.Ref.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.Ref.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Folios.Ref.Date";
		vQry.SetParameter("qRefArray", pRefArray);
		If ValueIsFilled(ObjectRef) Then
			vQry.SetParameter("qGuestGroup", ObjectRef.GuestGroup);
		Else
			vQry.SetParameter("qGuestGroup", Catalogs.GuestGroups.EmptyRef());
		EndIf;
		vQry.SetParameter("qEmptyGuestGroup", Catalogs.GuestGroups.EmptyRef());
		vQry.SetParameter("qClientsArray", vClientsList);
		vQry.SetParameter("qCustomersArray", vCustomersList);
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qCompany", vHotel.Company);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Clients") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref
		|INTO ClientFAs
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.Client IN(&qRefArray)
		|	AND Folios.ParentDoc.Number IS NULL
		|	AND Folios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|	AND (Folios.Company = &qCompany
		|			OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|	AND (Folios.Hotel = &qHotel
		|			OR Folios.IsMaster)
		|	AND NOT Folios.IsArchived
		|	AND NOT Folios.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Folios.Ref AS Ref
		|INTO ClientDocFolios
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.Client IN(&qRefArray)
		|	AND NOT Folios.ParentDoc.Number IS NULL
		|	AND NOT Folios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|	AND (Folios.Company = &qCompany
		|			OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|	AND (Folios.Hotel = &qHotel
		|			OR Folios.IsMaster)
		|	AND NOT Folios.IsArchived
		|	AND NOT Folios.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Folios.Ref AS Ref
		|INTO ClientGGFolios
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.Client IN(&qRefArray)
		|	AND Folios.ParentDoc.Number IS NULL
		|	AND NOT Folios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|	AND (Folios.Company = &qCompany
		|			OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|	AND (Folios.Hotel = &qHotel
		|			OR Folios.IsMaster)
		|	AND NOT Folios.IsArchived
		|	AND NOT Folios.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AllClientFolios.Ref AS Ref,
		|	AllClientFolios.Type AS Type
		|INTO Folios
		|FROM
		|	(SELECT
		|		ClientFAs.Ref AS Ref,
		|		3 AS Type
		|	FROM
		|		ClientFAs AS ClientFAs
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ClientGGFolios.Ref,
		|		1
		|	FROM
		|		ClientGGFolios AS ClientGGFolios
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ClientDocFolios.Ref,
		|		0
		|	FROM
		|		ClientDocFolios AS ClientDocFolios) AS AllClientFolios
		|
		|GROUP BY
		|	AllClientFolios.Ref,
		|	AllClientFolios.Type
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Folios.Ref AS Ref,
		|	Folios.Type AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.Ref.ParentDoc AS ParentDoc,
		|	Folios.Ref.ParentDoc.Date AS ParentDocDate,
		|	Folios.Ref.Number AS Number,
		|	Folios.Ref.Date AS Date,
		|	Folios.Ref.Client AS Client,
		|	Folios.Ref.DateTimeFrom AS DateTimeFrom,
		|	Folios.Ref.DateTimeTo AS DateTimeTo,
		|	Folios.Ref.Customer AS Customer,
		|	Folios.Ref.Contract AS Contract,
		|	Folios.Ref.Remarks AS Remarks,
		|	Folios.Ref.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.Ref.ParentDoc.Duration AS Duration,
		|	Folios.Ref.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.Ref.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.Ref.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Folios AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|
		|ORDER BY
		|	Folios.Type,
		|	CASE
		|		WHEN Folios.Ref.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.Ref.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Folios.Ref.Date";
		vQry.SetParameter("qRefArray", pRefArray);
		vQry.SetParameter("qClientsArray", vClientsList);
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qCompany", vHotel.Company);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Customers") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	0 AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.ParentDoc AS ParentDoc,
		|	Folios.ParentDoc.Date AS ParentDocDate,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Customer AS Customer,
		|	Folios.Contract AS Contract,
		|	Folios.Remarks AS Remarks,
		|	Folios.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.ParentDoc.Duration AS Duration,
		|	Folios.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Document.Folio AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|WHERE
		|	(Folios.Customer IN (&qRefArray)
		|				AND Folios.ParentDoc.Number IS NULL
		|				AND Folios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|				AND (Folios.Company = &qCompany
		|					OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|				AND (Folios.Hotel = &qHotel
		|					OR Folios.IsMaster)
		|				AND NOT Folios.IsArchived
		|				AND NOT Folios.DeletionMark
		|			OR Folios.Ref IN (&qFoliosOnScreenList))
		|
		|ORDER BY
		|	CASE
		|		WHEN Folios.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qCompany", vHotel.Company);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.Contracts") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	0 AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.ParentDoc AS ParentDoc,
		|	Folios.ParentDoc.Date AS ParentDocDate,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Customer AS Customer,
		|	Folios.Contract AS Contract,
		|	Folios.Remarks AS Remarks,
		|	Folios.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.ParentDoc.Duration AS Duration,
		|	Folios.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Document.Folio AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|WHERE
		|	(Folios.Contract IN (&qRefArray)
		|				AND Folios.ParentDoc.Number IS NULL
		|				AND Folios.GuestGroup = VALUE(Catalog.GuestGroups.EmptyRef)
		|				AND (Folios.Company = &qCompany
		|					OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|				AND (Folios.Hotel = &qHotel
		|					OR Folios.IsMaster)
		|				AND NOT Folios.IsArchived
		|				AND NOT Folios.DeletionMark
		|			OR Folios.Ref IN (&qFoliosOnScreenList))
		|
		|ORDER BY
		|	CASE
		|		WHEN Folios.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qCompany", vHotel.Company);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") And Not vShowAllGroupFolios Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	1 AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.ParentDoc AS ParentDoc,
		|	Folios.ParentDoc.Date AS ParentDocDate,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Customer AS Customer,
		|	Folios.Contract AS Contract,
		|	Folios.Remarks AS Remarks,
		|	Folios.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.ParentDoc.Duration AS Duration,
		|	Folios.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Document.Folio AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|WHERE
		|	(Folios.GuestGroup IN (&qRefArray)
		|				AND Folios.ParentDoc.Number IS NULL
		|				AND NOT Folios.IsArchived
		|				AND NOT Folios.DeletionMark
		|			OR Folios.Ref IN (&qFoliosOnScreenList)
		|			OR Folios.Ref IN
		|				(SELECT
		|					GuestGroupChargingRules.ChargingFolio
		|				FROM
		|					Catalog.GuestGroups.ChargingRules AS GuestGroupChargingRules
		|				WHERE
		|					GuestGroupChargingRules.Ref IN (&qRefArray)))
		|
		|ORDER BY
		|	CASE
		|		WHEN Folios.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") And vShowAllGroupFolios Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	CASE
		|		WHEN Folios.ParentDoc.Number IS NULL
		|			THEN 1
		|		ELSE 0
		|	END AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.ParentDoc AS ParentDoc,
		|	Folios.ParentDoc.Date AS ParentDocDate,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Customer AS Customer,
		|	Folios.Contract AS Contract,
		|	Folios.Remarks AS Remarks,
		|	Folios.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.ParentDoc.Duration AS Duration,
		|	Folios.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Document.Folio AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|WHERE
		|	(Folios.GuestGroup IN (&qRefArray)
		|				AND NOT Folios.IsArchived
		|				AND NOT Folios.DeletionMark
		|			OR Folios.Ref IN (&qFoliosOnScreenList)
		|			OR Folios.Ref IN
		|				(SELECT
		|					GuestGroupChargingRules.ChargingFolio
		|				FROM
		|					Catalog.GuestGroups.ChargingRules AS GuestGroupChargingRules
		|				WHERE
		|					GuestGroupChargingRules.Ref IN (&qRefArray)))
		|
		|ORDER BY
		|	CASE
		|		WHEN Folios.ParentDoc.Number IS NULL
		|			THEN 1
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN Folios.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.RoomQuotas") Then
		vQry.Text =
		"SELECT
		|	AllotmentFolios.Ref AS Ref,
		|	AllotmentFolios.Type AS Type,
		|	NULL AS CurrentDocument,
		|	AllotmentFolios.Ref.ParentDoc AS ParentDoc,
		|	AllotmentFolios.Ref.ParentDoc.Date AS ParentDocDate,
		|	AllotmentFolios.Ref.Number AS Number,
		|	AllotmentFolios.Ref.Date AS Date,
		|	AllotmentFolios.Ref.Client AS Client,
		|	AllotmentFolios.Ref.DateTimeFrom AS DateTimeFrom,
		|	AllotmentFolios.Ref.DateTimeTo AS DateTimeTo,
		|	AllotmentFolios.Ref.Customer AS Customer,
		|	AllotmentFolios.Ref.Contract AS Contract,
		|	CAST(AllotmentFolios.Ref.Remarks AS STRING(999)) AS Remarks,
		|	AllotmentFolios.Ref.ParentDoc.CheckInDate AS CheckInDate,
		|	AllotmentFolios.Ref.ParentDoc.Duration AS Duration,
		|	AllotmentFolios.Ref.ParentDoc.CheckOutDate AS CheckOutDate,
		|	AllotmentFolios.Ref.ParentDoc.AccommodationType AS AccommodationType,
		|	AllotmentFolios.Ref.FolioCurrency AS FolioCurrency,
		|	SUM(ISNULL(AccountsBalance.SumBalance, 0)) AS Balance,
		|	SUM(ISNULL(AccountsBalance.LimitBalance, 0)) AS LimitBalance
		|FROM
		|	(SELECT
		|		Folios.Ref AS Ref,
		|		0 AS Type
		|	FROM
		|		Document.Folio AS Folios
		|	WHERE
		|		(Folios.GuestGroup.Allotment IN (&qRefArray)
		|					AND Folios.ParentDoc.Number IS NULL
		|					AND (Folios.Company = &qCompany
		|						OR Folios.Company = VALUE(Catalog.Companies.EmptyRef))
		|					AND (Folios.Hotel = &qHotel
		|						OR Folios.IsMaster)
		|					AND NOT Folios.IsArchived
		|					AND NOT Folios.DeletionMark
		|				OR Folios.Ref IN (&qFoliosOnScreenList))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		EventFolios.Ref,
		|		0
		|	FROM
		|		Document.Folio AS EventFolios
		|	WHERE
		|		EventFolios.ParentDoc.GuestGroup.Allotment IN(&qRefArray)
		|		AND EventFolios.ParentDoc REFS Document.ResourceReservation
		|		AND (EventFolios.Company = &qCompany
		|				OR EventFolios.Company = VALUE(Catalog.Companies.EmptyRef))
		|		AND (EventFolios.Hotel = &qHotel
		|				OR EventFolios.IsMaster)
		|		AND NOT EventFolios.IsArchived
		|		AND NOT EventFolios.DeletionMark) AS AllotmentFolios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON AllotmentFolios.Ref = AccountsBalance.Folio
		|
		|GROUP BY
		|	AllotmentFolios.Ref,
		|	AllotmentFolios.Type,
		|	AllotmentFolios.Ref.ParentDoc,
		|	AllotmentFolios.Ref.ParentDoc.Date,
		|	AllotmentFolios.Ref.Number,
		|	AllotmentFolios.Ref.Date,
		|	AllotmentFolios.Ref.Client,
		|	AllotmentFolios.Ref.DateTimeFrom,
		|	AllotmentFolios.Ref.DateTimeTo,
		|	AllotmentFolios.Ref.Customer,
		|	AllotmentFolios.Ref.Contract,
		|	CAST(AllotmentFolios.Ref.Remarks AS STRING(999)),
		|	AllotmentFolios.Ref.ParentDoc.CheckInDate,
		|	AllotmentFolios.Ref.ParentDoc.Duration,
		|	AllotmentFolios.Ref.ParentDoc.CheckOutDate,
		|	AllotmentFolios.Ref.ParentDoc.AccommodationType,
		|	AllotmentFolios.Ref.FolioCurrency
		|
		|ORDER BY
		|	Type,
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qCompany", vHotel.Company);
	ElsIf TypeOf(ObjectRef) = Type("DocumentRef.Folio") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	0 AS Type,
		|	NULL AS CurrentDocument,
		|	Folios.ParentDoc AS ParentDoc,
		|	Folios.ParentDoc.Date AS ParentDocDate,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Customer AS Customer,
		|	Folios.Contract AS Contract,
		|	Folios.Remarks AS Remarks,
		|	Folios.ParentDoc.CheckInDate AS CheckInDate,
		|	Folios.ParentDoc.Duration AS Duration,
		|	Folios.ParentDoc.CheckOutDate AS CheckOutDate,
		|	Folios.ParentDoc.AccommodationType AS AccommodationType,
		|	Folios.FolioCurrency AS FolioCurrency,
		|	ISNULL(AccountsBalance.SumBalance, 0) AS Balance,
		|	-ISNULL(AccountsBalance.LimitBalance, 0) AS LimitBalance
		|FROM
		|	Document.Folio AS Folios
		|		LEFT JOIN AccumulationRegister.Accounts.Balance(DATETIME(3999, 12, 31, 23, 59, 59), ) AS AccountsBalance
		|		ON Folios.Ref = AccountsBalance.Folio
		|WHERE
		|	(Folios.Ref IN (&qRefArray)
		|				AND NOT Folios.DeletionMark
		|			OR Folios.Ref IN (&qFoliosOnScreenList))
		|
		|ORDER BY
		|	CASE
		|		WHEN Folios.LineNumber = 0
		|			THEN 999999
		|		ELSE Folios.LineNumber
		|	END" + ?(vShowExtrasFoliosFirst, " DESC", "") + ",
		|	Date";
		vQry.SetParameter("qRefArray", pRefArray);
	EndIf;
	vFoliosOnScreenList = New ValueList();
	If ValueIsFilled(FolioRefLeft) Then
		vFoliosOnScreenList.Add(FolioRefLeft);
	EndIf;
	If ValueIsFilled(FolioRefRight) Then
		vFoliosOnScreenList.Add(FolioRefRight);
	EndIf;
	vQry.SetParameter("qFoliosOnScreenList", vFoliosOnScreenList);
	
	vQryResult = vQry.Execute().Unload();
	vQryResult.Columns.Add("RuleString");
	
	TClientBalance = "";
	TCustomerBalance = "";
	vClientBalance = 0;
	vCustomerBalance = 0;
	vBalanceCurrency = Undefined;
	
	vInd = 1;
	FoliosTypes.Clear();
	If pRefreshList Then
		FolioList.Clear();
	EndIf;
	For Each vFolioStr In vQryResult Do
		vFolioRef = vFolioStr.Ref;
		
		vIsPayed = False;
		vStrPresentation = "";
		vPreauthLimit = vFolioStr.LimitBalance;
		vBalance = vFolioStr.Balance;
		vStrPresentation = cmFormatSum(vBalance, vFolioRef.FolioCurrency, "NZ=");
		If vPreauthLimit <> 0 Then
			vStrPresentation = vStrPresentation + "/" + cmFormatSum(-vPreauthLimit, vFolioRef.FolioCurrency, "NZ=");
		EndIf;
		If vPreauthLimit >= vBalance Then
			vIsPayed = True;
		EndIf;
	
		If vBalanceCurrency = Undefined Then
			vBalanceCurrency = vFolioRef.FolioCurrency;
		EndIf;
			
		If Not ValueIsFilled(vFolioRef.Customer) Or ValueIsFilled(vFolioRef.Customer) And vFolioRef.Customer.IsIndividual Then
			vClientBalance = vClientBalance + cmConvertCurrencies(vBalance, vFolioRef.FolioCurrency, , vBalanceCurrency, , CurrentSessionDate(), vFolioRef.Hotel);
		Else
			vCustomerBalance = vCustomerBalance + cmConvertCurrencies(vBalance, vFolioRef.FolioCurrency, , vBalanceCurrency, , CurrentSessionDate(), vFolioRef.Hotel);
		EndIf;			
		
		vPic = PictureLib.Adult;
		If ValueIsFilled(vFolioRef.GuestGroup) And Not ValueIsFilled(vFolioRef.ParentDoc) Then
			vPic = PictureLib.Clients;
		ElsIf ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
			If ValueIsFilled(vFolioRef.ParentDoc) Then
				vPic = PictureLib.Customer;
			Else
				vPic = PictureLib.Customers;
			EndIf;
		ElsIf ValueIsFilled(vFolioRef.Client) And Not ValueIsFilled(vFolioRef.ParentDoc) And Not ValueIsFilled(vFolioRef.Customer) Then
			vPic = PictureLib.Individual;
		EndIf;
		vFolioListItem = FolioList.FindByValue(vFolioRef);
		If vFolioListItem = Undefined Then
			FolioList.Add(vFolioRef, vStrPresentation, vIsPayed, vPic);
		Else
			vFolioListItem.Presentation = vStrPresentation;
			vFolioListItem.Picture = vPic;
		EndIf;
		vInd = vInd + 1;
		
		vFTRow = FoliosTypes.Add();
		FillPropertyValues(vFTRow, vFolioStr);
		vFTRow.Folio = vFolioRef;
		vFTRow.Balance = vBalance;
	EndDo;
	If ValueIsFilled(FolioRefLeft) Then
		If FolioList.FindByValue(FolioRefLeft) = Undefined Then
			vBalance = vFolioRef.GetObject().pmGetBalance(, , , vPreauthLimit);
			vStrPresentation = cmFormatSum(vBalance, vFolioRef.FolioCurrency, "NZ=");
			vFolioListItem = FolioList.FindByValue(FolioRefLeft);
			If vFolioListItem = Undefined Then
				FolioList.Add(FolioRefLeft, vStrPresentation, vIsPayed, vPic);
			Else
				vFolioListItem.Presentation = vStrPresentation;
				vFolioListItem.Picture = vPic;
			EndIf;
			
			vFTRow = FoliosTypes.Add();
			vFTRow.Folio = FolioRefLeft;
			vFTRow.Type = 0;
			vFTRow.Client = FolioRefLeft.Client;
			vFTRow.Balance = vBalance;  
			vFTRow.FolioCurrency = vFolioRef.FolioCurrency; 
			If ValueIsFilled(vFolioRef.ParentDoc) And (TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") 
													Or TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Reservation")) Then 
				vFTRow.AccommodationType = vFolioRef.ParentDoc.AccommodationType;
				vFTRow.CheckInDate = vFolioRef.ParentDoc.CheckInDate;
				vFTRow.CheckOutDate = vFolioRef.ParentDoc.CheckOutDate;
				vFTRow.Duration = vFolioRef.ParentDoc.Duration;
			EndIf;
		EndIf;
	EndIf;	
	
	TClientBalance = cmFormatSum(vClientBalance, vBalanceCurrency, "NZ=");
	TCustomerBalance = cmFormatSum(vCustomerBalance, vBalanceCurrency, "NZ=");
	If vClientBalance > 0 Then
		Items.TClientBalance.TextColor = WebColors.Black;
	Else
		Items.TClientBalance.TextColor = WebColors.Green;
	EndIf;
	If vCustomerBalance > 0 Then
		Items.TCustomerBalance.TextColor = WebColors.Black;
	Else
		Items.TCustomerBalance.TextColor = WebColors.Green;
	EndIf;
EndProcedure // GetFolios

 // ------------------------------------------------------------------------------------------------
&AtServer
Function GetDocumentsArray()
	vDocumentsArray = New Array;
	vQry = New Query;
	If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Then
		vQry.Text = "SELECT
		            |	Accommodation.Ref AS Ref
		            |FROM
		            |	Document.Accommodation AS Accommodation
		            |WHERE
		            |	Accommodation.GuestGroup = &qGroup
		            |	AND Accommodation.Room = &qRoom
		            |	AND Accommodation.Ref <> &qDocRef
		            |	AND Accommodation.Posted
		            |	AND NOT Accommodation.DeletionMark
		            |	AND (Accommodation.AccommodationStatus.IsActive
		            |			OR Accommodation.AccommodationStatus.IsCheckIn
		            |			OR Accommodation.AccommodationStatus.IsInHouse
		            |			OR Accommodation.AccommodationStatus = &qAccStatus)
		            |
		            |ORDER BY
		            |	Accommodation.AccommodationType.SortCode";
		vQry.SetParameter("qAccStatus", ObjectRef.AccommodationStatus);
		vQry.SetParameter("qGuest", ObjectRef.Guest);
		vQry.SetParameter("qRoom", ObjectRef.Room);
		vQry.SetParameter("qAccType", ObjectRef.AccommodationType);
		vQry.SetParameter("qRoomIsFilled", ValueIsFilled(ObjectRef.Room));
	ElsIf TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
		vQry.Text = "SELECT
		            |	Reservation.Ref AS Ref,
		            |	Reservation.AccommodationType.SortCode AS AccommodationTypeSortCode
		            |FROM
		            |	Document.Reservation AS Reservation
		            |WHERE
		            |	Reservation.GuestGroup = &qGroup
		            |	AND (Reservation.Room = &qRoom
		            |				AND &qRoomIsFilled
		            |			OR Reservation.Number = &qNumber
		            |				AND NOT &qRoomIsFilled)
		            |	AND (Reservation.Guest <> &qGuest
		            |			OR Reservation.Guest = &qEmptyGuest
		            |				AND Reservation.AccommodationType <> &qAccType)
		            |	AND Reservation.Posted
		            |	AND NOT Reservation.DeletionMark
		            |	AND Reservation.Ref <> &qDocRef
		            |	AND (Reservation.ReservationStatus.IsActive
		            |			OR Reservation.ReservationStatus.IsCheckIn
		            |			OR Reservation.ReservationStatus.IsPreliminary
		            |			OR Reservation.ReservationStatus.IsInWaitingList
		            |			OR Reservation.ReservationStatus = &qReservStatus)
		            |
		            |UNION ALL
		            |
		            |SELECT
		            |	Accommodation.Ref,
		            |	Accommodation.AccommodationType.SortCode
		            |FROM
		            |	Document.Accommodation AS Accommodation
		            |WHERE
		            |	Accommodation.Reservation = &qDocRef
		            |
		            |ORDER BY
		            |	AccommodationTypeSortCode";
		vQry.SetParameter("qReservStatus", ObjectRef.ReservationStatus);
		vQry.SetParameter("qGuest", ObjectRef.Guest);
		vQry.SetParameter("qRoom", ObjectRef.Room);
		vQry.SetParameter("qAccType", ObjectRef.AccommodationType);
		vQry.SetParameter("qRoomIsFilled", ValueIsFilled(ObjectRef.Room));
	ElsIf TypeOf(ObjectRef) = Type("DocumentRef.ResourceReservation") Then
		vQry.Text = "SELECT
		            |	Reservation.Ref AS Ref
		            |FROM
		            |	Document.ResourceReservation AS Reservation
		            |WHERE
		            |	Reservation.GuestGroup = &qGroup
		            |	AND Reservation.Client <> &qClient
		            |	AND Reservation.Posted
		            |	AND NOT Reservation.DeletionMark
		            |	AND Reservation.Ref <> &qDocRef
		            |	AND (Reservation.ResourceReservationStatus.IsActive
		            |			OR Reservation.ResourceReservationStatus = &qResourceReservStatus)
		            |
		            |ORDER BY
		            |	Reservation.Resource.SortCode";
		vQry.SetParameter("qResourceReservStatus", ObjectRef.ResourceReservationStatus);
		vQry.SetParameter("qClient", ObjectRef.Client);
	Else
		If ValueIsFilled(ObjectRef) Then
			vDocumentsArray.Insert(0, ObjectRef);
		EndIf;
		Return vDocumentsArray;
	EndIf;
	vQry.SetParameter("qGroup", ObjectRef.GuestGroup);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qNumber", ObjectRef.Number);
	vQry.SetParameter("qDocRef", ObjectRef);
	vQryResult = vQry.Execute().Unload();
	vDocumentsArray = vQryResult.UnloadColumn("Ref");
	If ValueIsFilled(ObjectRef) Then
		vDocumentsArray.Insert(0, ObjectRef);
		If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(ObjectRef.Reservation) Then
			vDocumentsArray.Add(ObjectRef.Reservation);
		EndIf;
	EndIf;
	Return vDocumentsArray;
EndFunction //  GetDocumentsArray 

// ------------------------------------------------------------------------------------------------
&AtServer
Function NextRowIsChild(pTransactions, pTransactionRow)
	vIsChild = True;
	i = pTransactions.IndexOf(pTransactionRow);
	If (i + 1) < pTransactions.Count() And pTransactionRow.IsRoomRevenue Then
		vNextTransactionRow = pTransactions.Get(i + 1);
		If Not vNextTransactionRow.IsInPrice Or
		   vNextTransactionRow.GuestGroupCode <> pTransactionRow.GuestGroupCode Or 
		   vNextTransactionRow.ReservationNumber <> pTransactionRow.ReservationNumber Or
		   vNextTransactionRow.CorrectedServiceDate <> pTransactionRow.CorrectedServiceDate Then
			vIsChild = False;
		EndIf;
	Else
		vIsChild = False;
	EndIf;
	Return vIsChild;
EndFunction // NextRowIsChild

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillFolioPage(pFolio, pPage)  
	vTable = ThisObject[pPage];
	vTable.GetItems().Clear();
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;	
	If pFolio.IsClosed Then
		Items[pPage].BackColor = GetClosedFolioBackColor();
		Items[pPage].UseAlternationRowColor = False;
	Else
		Items[pPage].BackColor = StyleColors.FormBackColor;
		Items[pPage].UseAlternationRowColor = True;
	EndIf;
	vCurHotel = pFolio.Hotel;
	vCurClient = pFolio.Client;
	vCurCustomer = pFolio.Customer;
	vParentDoc = ?(ValueIsFilled(ParentDoc), ParentDoc, Undefined);
	vWriteOffBonusesAsDiscounts = False;
	If ValueIsFilled(vCurHotel) Then
		vWriteOffBonusesAsDiscounts = vCurHotel.WriteOffBonusesAsDiscounts;
	EndIf;
	If vWriteOffBonusesAsDiscounts Then
		If pPage = "FolioDocumentsLeft" Then
			Items.FolioDocumentsLeftBonusesPaymentLeft.Visible = True;
			Items.FolioDocumentsLeftBonusesPaymentLeft.Enabled = True;
			Items.FolioDocumentsLeftBonusesPaymentLeft1.Visible = True;
			Items.FolioDocumentsLeftBonusesPaymentLeft1.Enabled = True;
		Else
			Items.FolioDocumentsRightBonusesPaymentRight.Visible = True;
			Items.FolioDocumentsRightBonusesPaymentRight.Enabled = True;
			Items.FolioDocumentsRightBonusesPaymentRight1.Visible = True;
			Items.FolioDocumentsRightBonusesPaymentRight1.Enabled = True;
		EndIf;
	Else
		If pPage = "FolioDocumentsLeft" Then
			Items.FolioDocumentsLeftBonusesPaymentLeft.Visible = False;
			Items.FolioDocumentsLeftBonusesPaymentLeft.Enabled = False;
			Items.FolioDocumentsLeftBonusesPaymentLeft1.Visible = False;
			Items.FolioDocumentsLeftBonusesPaymentLeft1.Enabled = False;
		Else
			Items.FolioDocumentsRightBonusesPaymentRight.Visible = False;
			Items.FolioDocumentsRightBonusesPaymentRight.Enabled = False;
			Items.FolioDocumentsRightBonusesPaymentRight1.Visible = False;
			Items.FolioDocumentsRightBonusesPaymentRight1.Enabled = False;
		EndIf;
	EndIf;
	
	vQry = New Query();
	vQry.Text = GetTransactionsQueryText();

	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qRecordersList", Undefined);
	vQry.SetParameter("qParentDoc", vParentDoc);
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qHideCorrections", SelHideCorrections);
	vQry.SetParameter("qEmptyCharge", Documents.Charge.EmptyRef());
	vQry.SetParameter("qShowInvoices", True);
	vQry.SetParameter("qParentDocIsUndefined", vParentDoc = Undefined);
	vQry.SetParameter("qRecordersListIsUndefined", True);
	vQry.SetParameter("qShowOrderItems", False);
	
	vAllTransactions = vQry.Execute().Unload();

	vTable = ThisObject[pPage];
	vTable.GetItems().Clear();
	
	vTotalSum = 0;
	vTotalPaymentSum = 0;
	vTotalPreauthSum = 0;
	vTotalItemsCount = 0;
	
	vCurGroupCode = -1;
	vCurReservationNumber = Undefined;
	vCurDate = Undefined;
	vCurDateItem = Undefined;
	For Each vTransactionRow In vAllTransactions Do
		vDocument = vTransactionRow.Document;
		vServiceDate = vTransactionRow.ServiceDate;
		vCorrectedServiceDate = vTransactionRow.CorrectedServiceDate;
		
		If TypeOf(vDocument) = Type("DocumentRef.Payment") Or 
		   TypeOf(vDocument) = Type("DocumentRef.Settlement") Or 
		   TypeOf(vDocument) = Type("DocumentRef.CreditNote") Or 
		   TypeOf(vDocument) = Type("DocumentRef.DebitNote") Or 
		   TypeOf(vDocument) = Type("DocumentRef.DepositTransfer") Then
			vNewRow = vTable.GetItems().Add();
			vNewRow.IsPayment = True;
			vNewRow.Date = vTransactionRow.ServiceDate;
			vNewRow.Service = TrimAll(vTransactionRow.Service);
			vNewRow.Remarks = vTransactionRow.Remarks;
			vNewRow.Invoice = vTransactionRow.Invoice;
			vNewRow.Sum = 0;
			vNewRow.PaymentSum = 0;
			vNewRow.PreauthSum = 0;
			vPaymentMethod = vTransactionRow.DocumentPaymentMethod;
			If TypeOf(vDocument) = Type("DocumentRef.DepositTransfer") Then
				vNewRow.Service = NStr("en='Deposit transfer';ru='Перенос депозита';de='Übertragung des Deposits'") + " - " + String(vPaymentMethod);
			Else
				vNewRow.Service = String(vPaymentMethod);
			EndIf;
			If TypeOf(vDocument) = Type("DocumentRef.Payment") Then
				If ValueIsFilled(vPaymentMethod.IsByCreditCard) Then
					If Not IsBlankString(vTransactionRow.DocumentTerminalNumber) Then
						vNewRow.Service = vNewRow.Service + " - Terminal N " + TrimAll(vTransactionRow.DocumentTerminalNumber);
					EndIf;
					If Not IsBlankString(vTransactionRow.DocumentReferenceNumber) Then
						vNewRow.Service = vNewRow.Service + " - Ref. N " + TrimAll(vTransactionRow.DocumentReferenceNumber);
					EndIf;
					If Not IsBlankString(vTransactionRow.DocumentAuthorizationCode) Then
						vNewRow.Service = vNewRow.Service + " - Auth. code " + TrimAll(vTransactionRow.DocumentAuthorizationCode);
					EndIf;
				EndIf;
				If ValueIsFilled(vTransactionRow.DocumentPaymentSection) Then
					vNewRow.Service = vNewRow.Service + " - " + String(vTransactionRow.DocumentPaymentSection);
				EndIf;
				vDiscountCard = vTransactionRow.DocumentDiscountCard;
				If ValueIsFilled(vDiscountCard) Then
					vNewRow.Service = vNewRow.Service + " - " + TrimAll(vDiscountCard.DiscountType) + " " + TrimAll(vDiscountCard.Identifier);
					If Not vPaymentMethod.IsByGiftCertificate And Not vPaymentMethod.IsByBonuses Then
						vNewRow.Service = vNewRow.Service + " - " + cmFormatSum(vTransactionRow.DocumentSum, vTransactionRow.DocumentFolioCurrency);
					EndIf;
				EndIf;
				If ValueIsFilled(vTransactionRow.DocumentPayer) And vTransactionRow.DocumentPayer <> vCurClient And vTransactionRow.DocumentPayer <> vCurCustomer Then
					vNewRow.Service = vNewRow.Service + " - " + TrimAll(vTransactionRow.DocumentPayerDescription);
				EndIf;
			EndIf;
			If TypeOf(vDocument) = Type("DocumentRef.CreditNote") Then
				vNewRow.Service = vNewRow.Service + NStr("en=' - credit note'; ru=' - кред. корректировка'; de=' - Gutschrift'");
			ElsIf TypeOf(vDocument) = Type("DocumentRef.DebitNote") Then
				vNewRow.Service = vNewRow.Service + NStr("en=' - debit note'; ru=' - дебет. корректировка'; de=' - Lastschrift'");
			ElsIf TypeOf(vDocument) = Type("DocumentRef.DepositTransfer") Then
				vFolioFrom = vTransactionRow.DocumentFolioFrom;
				vFromStr = NStr("en=' - from '; ru=' - от '; de=' - vom '");
				If ValueIsFilled(vTransactionRow.DocumentFolioFromRoom) Then
					vFromStr = vFromStr + NStr("en='room '; ru='номера '; de='Zimmer '") + TrimAll(vTransactionRow.DocumentFolioFromRoom);
				ElsIf ValueIsFilled(vTransactionRow.DocumentFolioFromClient) Then
					vFromStr = vFromStr + NStr("en='client '; ru='клиента '; de='Kunden '") + TrimAll(vTransactionRow.DocumentFolioFromClient);
				ElsIf ValueIsFilled(vTransactionRow.DocumentFolioFromCustomer) Then
					vFromStr = vFromStr + NStr("en='customer '; ru='заказчика '; de='Firma '") + TrimAll(vTransactionRow.DocumentFolioFromCustomer);
				Else
					vFromStr = vFromStr + NStr("en='folio N '; ru='лиц. счета № '; de='Folio Nr. '") + cmGetDocumentNumberPresentation(vTransactionRow.DocumentFolioFromNumber);
				EndIf;
				
				vFolioTo = vTransactionRow.DocumentFolioTo;
				vToStr = NStr("en=' to '; ru=' к '; de=' zu '");
				If ValueIsFilled(vTransactionRow.DocumentFolioToRoom) Then
					vToStr = vToStr + NStr("en='room '; ru='номеру '; de='Zimmer '") + TrimAll(vTransactionRow.DocumentFolioToRoom);
				ElsIf ValueIsFilled(vTransactionRow.DocumentFolioToClient) Then
					vToStr = vToStr + NStr("en='client '; ru='клиенту '; de='Kunden '") + TrimAll(vTransactionRow.DocumentFolioToClient);
				ElsIf ValueIsFilled(vTransactionRow.DocumentFolioToCustomer) Then
					vToStr = vToStr + NStr("en='customer '; ru='заказчику '; de='Firma '") + TrimAll(vTransactionRow.DocumentFolioToCustomer);
				Else
					vToStr = vToStr + NStr("en='folio N '; ru='лиц. счету № '; de='Folio Nr. '") + cmGetDocumentNumberPresentation(vTransactionRow.DocumentFolioToNumber);
				EndIf;
				
				vNewRow.Service = vNewRow.Service + vFromStr + vToStr;
			EndIf;
			vNewRow.PaymentSum = vTransactionRow.Sum;
			vNewRow.PaymentPresentation = cmFormatSum(vTransactionRow.Sum, pFolio.FolioCurrency);
			vTotalPaymentSum = vTotalPaymentSum + vTransactionRow.Sum;
			vTotalItemsCount = vTotalItemsCount + 1;
		ElsIf TypeOf(vDocument) = Type("DocumentRef.Return") Then
			vNewRow = vTable.GetItems().Add();
			vNewRow.IsPayment = True;
			vNewRow.Date = vTransactionRow.ServiceDate;
			vNewRow.Service = TrimAll(vTransactionRow.Service);
			vNewRow.Remarks = vTransactionRow.Remarks;
			vNewRow.Invoice = vTransactionRow.Invoice;
			vNewRow.Sum = 0;
			vNewRow.PaymentSum = 0;
			vNewRow.PreauthSum = 0;
			vPaymentMethod = vTransactionRow.DocumentPaymentMethod;
			vNewRow.Service = NStr("en='Refund';ru='Возврат';de='Rückzahlung'") + " - " + String(vTransactionRow.DocumentPaymentMethod);
			If ValueIsFilled(vPaymentMethod.IsByCreditCard) Then
				If Not IsBlankString(vTransactionRow.DocumentTerminalNumber) Then
					vNewRow.Service = vNewRow.Service + " - Terminal N " + TrimAll(vTransactionRow.DocumentTerminalNumber);
				EndIf;
				If Not IsBlankString(vTransactionRow.DocumentReferenceNumber) Then
					vNewRow.Service = vNewRow.Service + " - Ref. N " + TrimAll(vTransactionRow.DocumentReferenceNumber);
				EndIf;
				If Not IsBlankString(vTransactionRow.DocumentAuthorizationCode) Then
					vNewRow.Service = vNewRow.Service + " - Auth. code " + TrimAll(vTransactionRow.DocumentAuthorizationCode);
				EndIf;
			EndIf;
			If ValueIsFilled(vTransactionRow.DocumentPaymentSection) Then
				vNewRow.Service = vNewRow.Service + " - " + String(vTransactionRow.DocumentPaymentSection);
			EndIf;
			vDiscountCard = vTransactionRow.DocumentDiscountCard;
			If ValueIsFilled(vDiscountCard) Then
				vNewRow.Service = vNewRow.Service + " - " + TrimAll(vDiscountCard.DiscountType) + " " + TrimAll(vDiscountCard.Identifier);
				If Not vPaymentMethod.IsByGiftCertificate And Not vPaymentMethod.IsByBonuses Then
					vNewRow.Service = vNewRow.Service + " - " + cmFormatSum(vTransactionRow.DocumentSum, vTransactionRow.DocumentFolioCurrency);
				EndIf;
			EndIf;
			If ValueIsFilled(vTransactionRow.DocumentPayer) And vTransactionRow.DocumentPayer <> vCurClient And vTransactionRow.DocumentPayer <> vCurCustomer Then
				vNewRow.Service = TrimAll(vNewRow.Service) + " - " + TrimAll(vTransactionRow.DocumentPayerDescription);
			EndIf;
			vNewRow.PaymentSum = vTransactionRow.Sum;
			vNewRow.PaymentPresentation = cmFormatSum(vTransactionRow.Sum, pFolio.FolioCurrency);
			vTotalPaymentSum = vTotalPaymentSum + vTransactionRow.Sum;
			vTotalItemsCount = vTotalItemsCount + 1;
		ElsIf TypeOf(vDocument) = Type("DocumentRef.Preauthorisation") Then
			vNewRow = vTable.GetItems().Add();
			vNewRow.IsPayment = True;
			vNewRow.Date = vTransactionRow.ServiceDate;
			vNewRow.Service = TrimAll(vTransactionRow.Service);
			vNewRow.Remarks = vTransactionRow.Remarks;
			vNewRow.Invoice = vTransactionRow.Invoice;
			vNewRow.Sum = 0;
			vNewRow.PaymentSum = 0;
			vNewRow.PreauthSum = 0;
			vPaymentMethod = vTransactionRow.DocumentPaymentMethod;
			vNewRow.PreauthSum = vTransactionRow.Limit;
			vNewRow.Service = NStr("en='Preauthorisation - ';ru='Преавторизация - ';de='Vorautorisierung - '") + String(vTransactionRow.DocumentPaymentMethod);
			If ValueIsFilled(vPaymentMethod.IsByCreditCard) Then
				If Not IsBlankString(vTransactionRow.DocumentTerminalNumber) Then
					vNewRow.Service = vNewRow.Service + " - Terminal N " + TrimAll(vTransactionRow.DocumentTerminalNumber);
				EndIf;
				If Not IsBlankString(vTransactionRow.DocumentReferenceNumber) Then
					vNewRow.Service = vNewRow.Service + " - Ref. N " + TrimAll(vTransactionRow.DocumentReferenceNumber);
				EndIf;
				If Not IsBlankString(vTransactionRow.DocumentAuthorizationCode) Then
					vNewRow.Service = vNewRow.Service + " - Auth. code " + TrimAll(vTransactionRow.DocumentAuthorizationCode);
				EndIf;
			EndIf;
			vNewRow.PreauthPresentation = cmFormatSum(vTransactionRow.Limit, pFolio.FolioCurrency);
			vTotalPreauthSum = vTotalPreauthSum + vTransactionRow.Limit;
			vTotalItemsCount = vTotalItemsCount + 1;
		Else
			If SelHideCorrections And vTransactionRow.Sum = 0 And vTransactionRow.Quantity = 0 Then
				Continue;
			EndIf;
			vDoParentUpdate = False;
			If vTransactionRow.IsInPrice Then
				If vCurGroupCode <> vTransactionRow.GuestGroupCode Or 
				   vCurReservationNumber <> vTransactionRow.ReservationNumber Or
				   vCurDate <> vCorrectedServiceDate Then
					
					vCurGroupCode = vTransactionRow.GuestGroupCode;
					vCurReservationNumber = vTransactionRow.ReservationNumber;
					vCurDate = vCorrectedServiceDate;
					
					If NextRowIsChild(vAllTransactions, vTransactionRow) Then
						vCurDateItem = vTable.GetItems().Add();
						vCurDateItem.IsPayment = False;
						vCurDateItem.Date = vServiceDate;
						vCurDateItem.Service = TrimAll(vTransactionRow.Service);
						If Not IsBlankString(TrimAll(vTransactionRow.Room)) Then
							vCurDateItem.Service = vCurDateItem.Service + " - " + TrimAll(vTransactionRow.Room);
						EndIf;
						If Not IsBlankString(TrimAll(vTransactionRow.ClientFullName)) Then
							vCurDateItem.Service = vCurDateItem.Service + " - " + TrimAll(vTransactionRow.ClientFullName);
						EndIf;
						vCurDateItem.Remarks = vTransactionRow.Remarks;
						vCurDateItem.Invoice = vTransactionRow.Invoice;
						
						vCurDateItem.Sum = vTransactionRow.Sum;
						vCurDateItem.SumPresentation = cmFormatSum(vCurDateItem.Sum, pFolio.FolioCurrency);
						
						If Not IsBlankString(vCurDateItem.Remarks) Then
							vCurDateItem.Service = vCurDateItem.Service + " - " + TrimAll(vCurDateItem.Remarks);
						EndIf;
						vCurDateItem.IsCorrection = vTransactionRow.IsCorrection;
						vCurDateItem.IsChargeTransfer = False;
						vCurDateItem.IsStorno = vTransactionRow.IsStorno;
						vTotalItemsCount = vTotalItemsCount + 1;
						
						If vTransactionRow.IsRoomRevenue And vTransactionRow.IsInPrice Then
							vNewRow = vCurDateItem.GetItems().Add();
						Else
							vNewRow = vCurDateItem;
							vTotalItemsCount = vTotalItemsCount - 1;
						EndIf;
					Else
						vCurDateItem = Undefined;
						vNewRow = vTable.GetItems().Add();
					EndIf;
				ElsIf vCurDateItem <> Undefined Then
					vDoParentUpdate = True;
					vNewRow = vCurDateItem.GetItems().Add();
				Else
					vNewRow = vTable.GetItems().Add();
				EndIf;
			Else
				vNewRow = vTable.GetItems().Add();
			EndIf;
			vNewRow.IsPayment = False;
			vNewRow.Date = vTransactionRow.ServiceDate;
			vNewRow.Service = TrimAll(vTransactionRow.Service);
			vNewRow.Remarks = vTransactionRow.Remarks;
			vNewRow.Invoice = vTransactionRow.Invoice;
			vNewRow.Sum = 0;
			vNewRow.PaymentSum = 0;
			vNewRow.PreauthSum = 0;
			
			If Not IsBlankString(TrimAll(vTransactionRow.Room)) Then
				vNewRow.Service = vNewRow.Service + " - " + TrimAll(vTransactionRow.Room);
			EndIf;
			If Not IsBlankString(TrimAll(vTransactionRow.ClientFullName)) Then
				vNewRow.Service = vNewRow.Service + " - " + TrimAll(vTransactionRow.ClientFullName);
			EndIf;
			vNewRow.Sum = vTransactionRow.Sum;
			vNewRow.SumPresentation = cmFormatSum(vNewRow.Sum, pFolio.FolioCurrency);
			
			If vDoParentUpdate And vCurDateItem <> Undefined Then
				vCurDateItem.Sum = vCurDateItem.Sum + vTransactionRow.Sum;
				vCurDateItem.SumPresentation = cmFormatSum(vCurDateItem.Sum, pFolio.FolioCurrency);
			EndIf;
			
			vTotalSum = vTotalSum + vTransactionRow.Sum;
			vTotalItemsCount = vTotalItemsCount + 1;
		EndIf;
		If Not IsBlankString(vNewRow.Remarks) Then
			vNewRow.Service = vNewRow.Service + " - " + TrimAll(vNewRow.Remarks);
		EndIf;
		vNewRow.Ref = vDocument;
		vNewRow.IsCorrection = vTransactionRow.IsCorrection;
		vNewRow.IsStorno = vTransactionRow.IsStorno;
		vNewRow.IsChargeTransfer = False;
	EndDo;
	If SelShowTransfers Then
		vFolioObj = pFolio.GetObject();
		vTransfers = vFolioObj.pmGetFolioFromChargeTransfers();
		For Each vTransfersRow In vTransfers Do
			vDocument = vTransfersRow.Document;
			
			vNewRow = vTable.GetItems().Add();
			vNewRow.Date = vTransfersRow.ServiceDate;
			vNewRow.Remarks = vTransfersRow.Remarks;
			vNewRow.Invoice = Undefined;
			vNewRow.Sum = vTransfersRow.Sum;
			vNewRow.PreauthSum = 0;
			vNewRow.Service = TrimAll(vTransfersRow.ServiceDescription) + " - " + NStr("en='transfered to '; ru='перемещено на '; de='verschoben auf '") + TrimAll(vTransfersRow.Room) + ", " + TrimAll(vTransfersRow.ClientFullName) + " - " + cmFormatSum(vTransfersRow.Sum, pFolio.FolioCurrency);
			If Not IsBlankString(vNewRow.Remarks) Then
				vNewRow.Service = vNewRow.Service + " - " + TrimAll(vNewRow.Remarks);
			EndIf;
			vNewRow.SumPresentation = "";
			vNewRow.IsPayment = False;
			vNewRow.Ref = vDocument;
			vNewRow.IsCorrection = False;
			vNewRow.IsStorno = False;
			vNewRow.IsChargeTransfer = True;
			
			vTotalItemsCount = vTotalItemsCount + 1;
		EndDo;
	EndIf;
	// Fill table totals
	Items[pPage + "SumPresentation"].FooterText = cmFormatSum(vTotalSum, pFolio.FolioCurrency);
	Items[pPage + "PaymentPresentation"].FooterText = cmFormatSum(vTotalPaymentSum, pFolio.FolioCurrency);
	Items[pPage + "PreauthPresentation"].FooterText = cmFormatSum(vTotalPreauthSum, pFolio.FolioCurrency);
	// Try to restore list position
	vID = 0;
	If pPage = "FolioDocumentsLeft" Then
		vID = CurLeftListTransactionID;
	Else
		vID = CurRightListTransactionID;
	EndIf;
	If vID > 0 Then
		vID = vID + vTotalItemsCount;
		If ThisObject[pPage].FindByID(vID) <> Undefined Then
			Items[pPage].CurrentRow = vID;
		ElsIf vID > 1 Then
			vID = vID - 1;
			If ThisObject[pPage].FindByID(vID) <> Undefined Then
				Items[pPage].CurrentRow = vID;
			EndIf;
		EndIf;
	EndIf;
	// Check advances balances
	If ValueIsFilled(AdvancePaymentSection) And ValueIsFilled(AdvanceSettlementPaymentMethod) Then
		vFolioObj = pFolio.GetObject();
		vAdvances = vFolioObj.pmGetPaymentSectionBalances(, vFolioObj.Hotel, , True);
		vAdvancesBalance = 0;
		If vAdvances.Count() > 0 Then
			For Each vAdvancesRow In vAdvances Do
				If vAdvancesRow.SumBalance <> Null And cmIsNumber(vAdvancesRow.SumBalance) Then
					vAdvancesBalance = vAdvancesBalance + vAdvancesRow.SumBalance;
				EndIf;
			EndDo;
		EndIf;
		If vAdvancesBalance >= 0 Then
			If pPage = "FolioDocumentsLeft" Then
				Items.AdvanceSettlementChequeLeft.Enabled = False;
			Else
				Items.AdvanceSettlementChequeRight.Enabled = False;
			EndIf;
		Else
			If ValueIsFilled(vFolioObj.PaymentMethod) And (vFolioObj.PaymentMethod.PrintCheque Or vFolioObj.PaymentMethod.ChequesArePrintedAtExternalCashRegister) Then
				If pPage = "FolioDocumentsLeft" Then
					Items.AdvanceSettlementChequeLeft.Enabled = True;
				Else
					Items.AdvanceSettlementChequeRight.Enabled = True;
				EndIf;
			Else
				If pPage = "FolioDocumentsLeft" Then
					Items.AdvanceSettlementChequeLeft.Enabled = False;
				Else
					Items.AdvanceSettlementChequeRight.Enabled = False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ChangePaymentFolio(pDoc, pFolioTo)
	vDocObj = pDoc.GetObject();
	vDocObj.Folio = pFolioTo;
	vDocObj.Write(DocumentWriteMode.Posting);
EndProcedure // ChangePaymentFolio

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetSumTransactions(pTransactions)
	vSum = 0;
	vSumCurrency = Undefined;
	For Each vTran In pTransactions Do
		vRow = vTran.Value;
		If ValueIsFilled(vRow) And TypeOf(vRow) = Type("DocumentRef.DepositTransfer") Then
			vSum = vSum + vRow.SumInFolioToCurrency;
			vSumCurrency = vRow.FolioToCurrency;
		Else	
			vSum = vSum + vRow.Sum;
			vSumCurrency = vRow.FolioCurrency;
		EndIf;
	EndDo;
	vSumStr = cmFormatSum(vSum, vSumCurrency, "NZ=");
	Return	vSumStr;
EndFunction	

// ------------------------------------------------------------------------------------------------
&AtClient
Function GetSumChargeActivateRow(pPage, pCountSelected = 0)
	pCountSelected = 0;
	vTotalSelected = 0;
	
	vCurFolio = Undefined;
	If pPage = "FolioDocumentsLeft" Then
		vCurFolio = FolioRefLeft;
	ElsIf pPage = "FolioDocumentsRight" Then 
		vCurFolio = FolioRefRight;
	EndIf;
	
	vTable = Items[pPage];
	vRows = GetSelectedRows(vTable.Name);
	If vRows.Count() > 0 Then
		For Each vStr In vRows Do
			vStrData = ThisObject[pPage].FindByID(vStr);
			// Check is it Charge or Storno
			If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Or TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Then
				pCountSelected = pCountSelected + 1;
				vTotalSelected = vTotalSelected + vStrData.Sum;
				vFolioCurrency = tcOnServer.cmGetAttributeByRef(vCurFolio, "FolioCurrency");
			EndIf;	
		EndDo;
	EndIf;
	pCountSelected = Format(pCountSelected, "ND=7; NFD=0; NZ=; NG=");
	Return tcOnServer.FormatSum(vTotalSelected, vFolioCurrency, "NZ=");
EndFunction	//GetSumChargeActivateRow

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetTasksStructure(pObjectRef)
	vTasksStructure = New Structure();
	If ValueIsFilled(pObjectRef) Then
		vTasks = cmGetMessagesForObject(pObjectRef);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks, ReservationTaskArea", vTasksRow.PopUp, vTasksRow.Remarks, vTasksRow.ReservationTaskArea));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ControlVisibility(pPage = "")
	If amClipboard.Property("TransferTransactionsType") Then
		// Show clipboard content
		If FolioRefRight.IsEmpty() Then
			Items.FolioDocumentsLeftTransfer.Check = True;
			Items.FolioDocumentsLeftTransfer1.Check = True;
			Items.FolioDocumentsLeftPaste.Enabled = Not amClipboard.TransferFolioFrom = FolioRefLeft;
			Items.FolioDocumentsRightPaste.Enabled = False;
		Else
			Items.FolioDocumentsLeftTransfer.Check = True;
			Items.FolioDocumentsLeftTransfer1.Check = True;
			Items.FolioDocumentsRightTransfer.Check = True;
			Items.FolioDocumentsRightTransfer1.Check = True;
			Items.FolioDocumentsLeftPaste.Enabled = Not amClipboard.TransferFolioFrom = FolioRefLeft;
			Items.FolioDocumentsRightPaste.Enabled = Not amClipboard.TransferFolioFrom = FolioRefRight;
		EndIf;
		If Not pPage="" And GetSelectedRows(pPage).Count() > 1 Then
			vCountSelected = 0;
			vTotalSelected = GetSumChargeActivateRow(pPage,vCountSelected);
			TClipboardContent = NStr("en='" + Format(vCountSelected, "ND=7; NFD=0; NZ=; NG=") + " charges selected. Total amount ';
			                         |de='" + Format(vCountSelected, "ND=7; NFD=0; NZ=; NG=") + " charges selected. Total amount '; 
			                         |ru='Выбрано " + Format(vCountSelected, "ND=7; NFD=0; NZ=; NG=") + " начислений на сумму '") + vTotalSelected;	
		Else
			vTransactions = amClipboard.TransferTransactions;
			If vTransactions.Count() > 0 Then
				vCountStr = Format(vTransactions.Count(), "ND=6; NFD=0; NZ=");
				vSumStr = GetSumTransactions(vTransactions);
				
				TClipboardContent = NStr("en='Charge transfer is pending! " + vCountStr + " charges selected for total amount of " + vSumStr + "'; 
				                         |de='Charge transfer is pending! " + vCountStr + " charges selected for total amount of " + vSumStr + "'; 
				                         |ru='Начата операция переноса начислений! Выбрано " + vCountStr + " транзакций на общую сумму " + vSumStr + "'");
			Else
				TClipboardContent = NStr("en='Deposit transfer is pending!'; 
				                         |de='Deposit transfer is pending!'; 
				                         |ru='Начата операция переноса депозита!'");
			EndIf;
		EndIf;
	Else
		// Hide clipboard
		Items.FolioDocumentsLeftPaste.Enabled 		= False;
		Items.FolioDocumentsRightPaste.Enabled 		= False;
		Items.FolioDocumentsLeftTransfer.Check  	= False;
		Items.FolioDocumentsLeftTransfer1.Check  	= False;
		Items.FolioDocumentsRightTransfer.Check 	= False;
		Items.FolioDocumentsRightTransfer1.Check 	= False;
		If Not pPage="" Then
			vStrCount = GetSelectedRows(pPage).Count();
			If vStrCount > 1 Then
				vCountSelected = 0;
				vTotalSelected = GetSumChargeActivateRow(pPage, vCountSelected);
				TClipboardContent = NStr("en='" +  vCountSelected  + " charges selected. Total amount ';
				                         |de='" +  vCountSelected + " charges selected. Total amount '; 
				                         |ru='Выбрано " +  vCountSelected + " начислений на сумму '") + vTotalSelected;
			Else
				TClipboardContent = "";	
			EndIf;
		Else
			TClipboardContent = "";	
		EndIf;
	EndIf;
	// Visible panel
	If ObjectRef = Undefined Then
		Items.FolioDocumentsLeftPrint.Representation = ButtonRepresentation.PictureAndText;
	Else
		Items.FolioDocumentsLeftPrint.Representation = ButtonRepresentation.Picture;
	EndIf;
	// Split mode switch
	#IF MobileClient THEN
		If Items.Split.CheckBoxType <> CheckBoxType.Tumbler Then
			Items.Split.CheckBoxType = CheckBoxType.Tumbler;
		EndIf;
	#ENDIF
EndProcedure //  ControlVisibility 

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure AddNewTransactionToFolio(pTransactions, pFolioFrom, pFolioTo)
	If TypeOf(pTransactions) = Type("ValueList") Then 
		For Each vStr In pTransactions Do
			
			vStrData = vStr.Value;
			
			If TypeOf(vStrData.Ref) = Type("DocumentRef.Storno") Or TypeOf(vStrData.Ref) = Type("DocumentRef.Settlement") Or TypeOf(vStrData.Ref) = Type("DocumentRef.DepositTransfer") Then
				Continue;
			EndIf;
			pTransactionRef = vStrData.Ref; 
			
			Try
				If Not pTransactionRef.Folio.IsClosed Then
					If TypeOf(pTransactionRef) = Type("DocumentRef.Preauthorisation") Or TypeOf(pTransactionRef) = Type("DocumentRef.Payment") Or TypeOf(pTransactionRef) = Type("DocumentRef.Return") Then
						vFolioFrom = pTransactionRef.Folio;
						vHavePermissionToTransferDepositsBetweenGuestGroups = cmCheckUserPermissions("HavePermissionToTransferDepositsBetweenGuestGroups");
						vHavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = cmCheckUserPermissions("HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup");
						If vFolioFrom.FolioCurrency = pFolioTo.FolioCurrency And
						   (vFolioFrom.GuestGroup = pFolioTo.GuestGroup Or 
						    vHavePermissionToTransferDepositsBetweenGuestGroups) And 
						   (vFolioFrom.Customer = pFolioTo.Customer Or 
						    vHavePermissionToTransferDepositsBetweenGuestGroups) And
						   (vFolioFrom.Contract = pFolioTo.Contract Or 
						    vHavePermissionToTransferDepositsBetweenGuestGroups) And
						   (vFolioFrom.Client = pFolioTo.Client Or 
						    vHavePermissionToTransferDepositsBetweenGuestGroups Or 
						    vHavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup And vFolioFrom.GuestGroup = pFolioTo.GuestGroup) Then
							vDoc = pTransactionRef.GetObject();
							vDoc.Folio = pFolioTo;
							vDoc.Write(DocumentWriteMode.Posting);
						Else
							tcCommonFunctionOnClientServer.UserMessage(String(pTransactionRef) + " - " + NStr("en='could not be moved between selected folios because folios have different customer, group or client!'; 
							                                               |ru='нельзя переместить между выбранными лицевыми счетами, потому что у лицевых счетов разные контрагент, группа или клиент!'; 
																		   |de='konnte nicht zwischen ausgewählten Folios verschoben werden, da Folios unterschiedliche Firma, Gruppen oder Kunden haben!'"));
						EndIf;
					Else
						vDoc = Documents.ChargeTransfer.CreateDocument();
						tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"),, "Documents.ChargeTransfer", "Documents.ChargeTransfer.EmptyRef()", NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
						vDoc.Fill(pTransactionRef);
						vDoc.SetTime(AutoTimeMode.CurrentOrLast);
						vDoc.Date = CurrentSessionDate();
						vDoc.FolioTo = pFolioTo;
						vDoc.Write(DocumentWriteMode.Posting);
					EndIf;
				Else   
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='Charge is in closed folio! Operation will be canceled.'; ru='Начисление в закрытом лицевом счете! Операция будет отменена.'; de='Service in einem geschlossenen persönlichen Konto! Der Vorgang wird abgebrochen.'"));
				EndIf;
			Except
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),, "Documents.ChargeTransfer", "Documents.ChargeTransfer.EmptyRef()", ErrorDescription());
			EndTry;
		EndDo;
	EndIf;
EndProcedure // AddNewTransactionToFolio

// ------------------------------------------------------------------------------------------------
&AtServer
Function ChargeAtServer(pFolio)
	// Check user rights
	If pFolio.IsClosed Then
		Return NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Personenkonto geschlossen ist!'");
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditCustomerFolioTransactions") Then
		If ValueIsFilled(pFolio.PaymentMethod) And 
			pFolio.PaymentMethod.IsByBankTransfer Then
			Return NStr("en='You do not have rights to change customer folio transactions set!';ru='Нет прав на изменение набора транзакций по лицевым счетам контрагентов!';de='Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'");
		EndIf;
	EndIf;
	
	// Create new charge
	WriteLogEvent(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), EventLogLevel.Information, Metadata.Documents.Charge, Documents.Charge.EmptyRef(), NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
	Return "";
EndFunction // ChargeAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Function CheckUserPermissionsForTransactions(pFolio)
	If ValueIsFilled(pFolio) And tcOnServer.cmGetAttributeByRef(pFolio, "IsClosed") Then
		ShowMessageBox(, NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Personenkonto geschlossen ist!'"));
		Return False;
	EndIf;
	
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCustomerFolioTransactions") Then
		vFolioPaymentMethod = tcOnServer.cmGetAttributeByRef(pFolio, "PaymentMethod");
		If ValueIsFilled(vFolioPaymentMethod) Then
			vIsByBankTransfer = tcOnServer.cmGetAttributeByRef(vFolioPaymentMethod, "IsByBankTransfer");
			If vIsByBankTransfer Then
				ShowMessageBox(, NStr("en='You do not have rights to change customer folio transactions set!';ru='Нет прав на изменение набора транзакций по лицевым счетам контрагентов!';de='Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'"));
				Return False;
			EndIf;
		EndIf;
	EndIf;

	Return True;
EndFunction	// CheckUserPermissionsForTransactions

// ------------------------------------------------------------------------------------------------
&AtClient
Function CheckUserPermissionsForStorno(pFolio)
	vResult = CheckUserPermissionsForTransactions(pFolio);
	If Not vResult Then
		Return False;
	EndIf;
	
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStornoFolioCharges") Then
		ShowMessageBox(,NStr("en='You do not have rights to do reversal charges!';ru='Нет прав на сторнирование начислений!';de='Sie haben keine Rechte, Berechnungen zu stornieren!'"));
		Return False;
	EndIf;
	
	Return True;
EndFunction	// CheckUserPermissionsForStorno

// ------------------------------------------------------------------------------------------------
&AtServer
Function TransferAtServer(pFolio, pPage, pClipboard,rMessage="")
	// Check user rights
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCustomerFolioTransactions") Then
		If ValueIsFilled(FolioRefLeft.PaymentMethod) And 
		   FolioRefLeft.PaymentMethod.IsByBankTransfer Then
			rMessage = NStr("en='You do not have rights to change customer folio transactions set!';ru='Нет прав на изменение набора транзакций по лицевым счетам контрагентов!';de='Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'");
			Return False;
		EndIf;
	EndIf;
	// Add value table and insert charges
	vCurPreauthorisations = New ValueList;
	vCurCharges = New ValueList;
	vCurPayments = New ValueList;
	vRows = GetSelectedRows(pPage);
	If vRows.Count() > 0 Then
		For Each vStr In vRows Do
			vStrData = ThisObject[pPage].FindByID(vStr);
			// Check is it Charge
			If TypeOf(vStrData.Ref) = Type("DocumentRef.Charge") Then
				vCurCharges.Add(vStrData.Ref);
			ElsIf TypeOf(vStrData.Ref) = Type("DocumentRef.Preauthorisation") Then
				vCurPreauthorisations.Add(vStrData.Ref);
			ElsIf (TypeOf(vStrData.Ref) = Type("DocumentRef.Payment") Or TypeOf(vStrData.Ref) = Type("DocumentRef.Return") Or TypeOf(vStrData.Ref) = Type("DocumentRef.DepositTransfer")) Then
				vCurPayments.Add(vStrData.Ref);
			EndIf;	
		EndDo;
	EndIf;
	// Fill buffer
	If vCurCharges.Count() > 0 Then
		pClipboard.Insert("TransferTransactionsType", "ChargeTransfer");
		pClipboard.Insert("TransferTransactions", vCurCharges);
	ElsIf vCurPreauthorisations.Count() > 0 Then
		pClipboard.Insert("TransferTransactionsType", "PreauthorisationTransfer");
		pClipboard.Insert("TransferTransactions", vCurPreauthorisations);
	Else
		pClipboard.Insert("TransferTransactionsType", "DepositTransfer");
		pClipboard.Insert("TransferTransactions", vCurPayments);
	EndIf;
	pClipboard.Insert("TransferFolioFrom", pFolio);
	// Show button paste
	If pPage = "FolioDocumentsLeft" Then
		Items.FolioDocumentsRightPaste.Enabled = True;
	ElsIf pPage = "FolioDocumentsRight" Then
		Items.FolioDocumentsLeftPaste.Enabled  = True;
	EndIf;
	Return True;	
EndFunction	

// ------------------------------------------------------------------------------------------------
&AtServer
Function PasteAtServer(pFolio, pClipboard, rMessage="", rOpenDepositTransfer=False)
	rOpenDepositTransfer = False;
	CurFolio = pFolio; 
	// Check clipboard and do processing
	vTransferTransactionsType = Undefined;
	vTransferTransactions = Undefined;
	vTransferFolioFrom = Undefined;
	If pClipboard.Property("TransferTransactionsType", vTransferTransactionsType) And 
	   pClipboard.Property("TransferFolioFrom", vTransferFolioFrom) Then
		If vTransferTransactionsType = "ChargeTransfer" Or vTransferTransactionsType = "ChargeSplit" Then
			// Check user rights
			If CurFolio.IsClosed Then
				rMessage = NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Personenkonto geschlossen ist!'");
				Return False;
			EndIf;
			If Not cmCheckUserPermissions("HavePermissionToEditCustomerFolioTransactions") Then
				If ValueIsFilled(CurFolio.PaymentMethod) And 
					CurFolio.PaymentMethod.IsByBankTransfer Then
					rMessage = NStr("en='You do not have rights to change customer folio transactions set!';ru='Нет прав на изменение набора транзакций по лицевым счетам контрагентов!';de='Sie haben keine Rechte, den Transaktionsbestand nach  Personenkonten der Partner zu bearbeiten!'");
					Return False;
				EndIf;
			EndIf;
		EndIf;
		If vTransferTransactionsType = "ChargeTransfer" Or vTransferTransactionsType = "PreauthorisationTransfer" Then
			If vTransferFolioFrom <> Undefined And vTransferFolioFrom <> CurFolio Then
				If pClipboard.Property("TransferTransactions", vTransferTransactions) Then
					If vTransferTransactions.Count() > 0 Then
						AddNewTransactionToFolio(vTransferTransactions,vTransferFolioFrom,CurFolio);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vTransferTransactionsType = "DepositTransfer" Then
			If vTransferFolioFrom <> Undefined And vTransferFolioFrom <> CurFolio Then
				rOpenDepositTransfer = True;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // PasteAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure StornoAtServer(pDocList, pTypeOfStorno, pRemarks)
	For Each vDocRef In pDocList Do
		tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"),, 
												"Documents.Storno", "Documents.Storno.EmptyRef()", 
												 NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
												 
		vDoc = Documents.Storno.CreateDocument();
		vDoc.Fill(vDocRef);
		vDoc.SetTime(AutoTimeMode.CurrentOrLast);
		vDoc.Date = CurrentSessionDate();
		vDoc.TypeOfStorno = ?(pTypeOfStorno=0,Enums.CancelActionTypes.ClientRefusal,Enums.CancelActionTypes.EmployeeFault);
		vDoc.Remarks = pRemarks;
		vDoc.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // StornoAtServer()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillRightPanelHeader(pFolio)  
	If Not ValueIsFilled(pFolio) Then
		// Clear header
		Items.RightPanelPic.Picture = PictureLib.Attention;
		Items.RightPanelDecorationFolioClient.Title = "";
		Items.RightPanelFolioNumber.Title = "N/A";
		Items.RightPanelIsClosed.Title = NStr("en='No folios'; ru='Нет лиц. счетов'; de='Keine Folios'");
		Items.RightPanelBalance.Title = "0.00";
		Items.RightPanelBalance.TextColor = tcCommonFunctionOnClientServer.ColorConstructor(51, 51, 51);  
	EndIf;
	pRowList = FolioList.FindByValue(pFolio);
	If pRowList <> Undefined Then
		vClient = tcOnServer.cmGetAttributeByRef(FolioRefRight, "Client.FullName");
		vCustomer = tcOnServer.cmGetAttributeByRef(FolioRefRight, "Customer");
		vClientPres = ?(ValueIsFilled(vCustomer), String(vCustomer) + ", " + String(vClient), vClient);
		vFolioNumber = tcOnServer.GetDocumentNumberPresentation(tcOnServer.cmGetAttributeByRef(FolioRefRight, "Number"));
		vFolioDesc = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefRight, "Description"));
		vFolioRemarks = "";
		If Not Split Then
			vFolioRemarks = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefRight, "Remarks"));
		EndIf;
		vFolioIsClosed = tcOnServer.cmGetAttributeByRef(FolioRefRight, "IsClosed");
		vFolioPMCode = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefRight, "PaymentMethod.Code"));
		
		vSum = 0;
		vRowFT = FoliosTypes.FindRows(New Structure("Folio", FolioRefRight));
		vFolioCurrency = Undefined;
		If vRowFT.Count() > 0 Then
			vFT = vRowFT[0];
			vSum = vFT.Balance;
			vFolioCurrency = vFT.FolioCurrency;
		EndIf;	
		vSumPres = tcOnServer.cmFormattedSumString(vSum, ?(vFolioCurrency = Undefined, FolioRefRight.FolioCurrency, vFolioCurrency));   
		If vSum <= 0 Then
			vBalanceColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0);
		Else
			vBalanceColor = tcCommonFunctionOnClientServer.ColorConstructor(51, 51, 51);
		EndIf;
		
		// Header
		Items.RightPanelPic.Picture = pRowList.Picture;
		Items.RightPanelDecorationFolioClient.Title = vClientPres;
		Items.RightPanelFolioNumber.Title = "№" + vFolioNumber + ?(IsBlankString(vFolioDesc), "", ", " + vFolioDesc) + ?(IsBlankString(vFolioPMCode), "", ", " + vFolioPMCode) + ?(IsBlankString(vFolioRemarks), "", ", " + vFolioRemarks);
		Items.RightPanelIsClosed.Title = ?(vFolioIsClosed, NStr("en='Is closed'; ru='Закрыт'; de='Geschlossen'"), "");
		Items.RightPanelBalance.Title = vSumPres;
		Items.RightPanelBalance.TextColor = vBalanceColor;  
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillLeftPanelHeader(pFolio) 
	If Not ValueIsFilled(pFolio) Then
		// Clear header
		Items.LeftPanelPic.Picture = PictureLib.Attention;
		Items.LeftPanelDecorationFolioClient.Title = "";
		Items.LeftPanelFolioNumber.Title = "N/A";
		Items.LeftPanelIsClosed.Title = NStr("en='No folios'; ru='Нет лиц. счетов'; de='Keine Folios'");
		Items.LeftPanelBalance.Title = "0.00";
		Items.LeftPanelBalance.TextColor = tcCommonFunctionOnClientServer.ColorConstructor(51, 51, 51);  
	EndIf;
	pRowList = FolioList.FindByValue(pFolio);
	If pRowList <> Undefined Then
		vClient = tcOnServer.cmGetAttributeByRef(FolioRefLeft,"Client.FullName");
		vCustomer = tcOnServer.cmGetAttributeByRef(FolioRefLeft, "Customer");
		vClientPres = ?(ValueIsFilled(vCustomer), String(vCustomer) + ", " + String(vClient), vClient);
		vFolioNumber = tcOnServer.GetDocumentNumberPresentation(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "Number"));
		vFolioDesc = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefLeft,"Description"));
		vFolioRemarks = "";
		If Not Split Then
			vFolioRemarks = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "Remarks"));
		EndIf;
		vFolioIsClosed = tcOnServer.cmGetAttributeByRef(FolioRefLeft, "IsClosed");
		vFolioPMCode = TrimAll(tcOnServer.cmGetAttributeByRef(FolioRefLeft, "PaymentMethod.Code"));
		
		vSum = 0;
		vRowFT = FoliosTypes.FindRows(New Structure("Folio", FolioRefLeft));
		vFolioCurrency = Undefined;
		If vRowFT.Count() > 0 Then
			vFT = vRowFT[0];
			vSum = vFT.Balance;
			vFolioCurrency = vFT.FolioCurrency;
		EndIf;	
		vSumPres = tcOnServer.cmFormattedSumString(vSum, ?(vFolioCurrency = Undefined, FolioRefLeft.FolioCurrency, vFolioCurrency));
		If vSum <= 0 Then
			vBalanceColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0);
		Else
			vBalanceColor = tcCommonFunctionOnClientServer.ColorConstructor(51, 51, 51);
		EndIf;
		
		// Header
		Items.LeftPanelPic.Picture = pRowList.Picture;
		Items.LeftPanelDecorationFolioClient.Title = vClientPres;
		Items.LeftPanelFolioNumber.Title = "№" + vFolioNumber + ?(IsBlankString(vFolioDesc), "", ", " + vFolioDesc) + ?(IsBlankString(vFolioPMCode), "", ", " + vFolioPMCode) + ?(IsBlankString(vFolioRemarks), "", ", " + vFolioRemarks);
		Items.LeftPanelIsClosed.Title = ?(vFolioIsClosed, NStr("en='Is closed'; ru='Закрыт'; de='Geschlossen'"), "");
		Items.LeftPanelBalance.Title = vSumPres;
		Items.LeftPanelBalance.TextColor = vBalanceColor;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnReopenAtServer()
	If Not ObjectRef = Undefined Then
		If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
			Title = NStr("en='Room: ';ru='Номер: ';de='Zimmer: '") + TrimAll(ObjectRef.Room) + NStr("en='; guest group: ';ru='; группа гостей: ';de='; Gästegruppe: '") + TrimAll(ObjectRef.GuestGroup) + 
			                 NStr("en='; period '; ru='; период ';de=' Periode '") + Format(ObjectRef.CheckInDate, "DF=dd.MM.yy") + " - " + Format(ObjectRef.CheckOutDate, "DF=dd.MM.yy");
			Items.ParentDocDecoration.Title = TrimAll(ObjectRef);
		ElsIf TypeOf(ObjectRef) = Type("DocumentRef.ResourceReservation") Then
			Title = NStr("en='Resource: ';ru='Ресурс: ';de='Ressource: '") + TrimAll(ObjectRef.Resource) + NStr("en='; guest group: ';ru='; группа гостей: ';de='; Gästegruppe: '") + TrimAll(ObjectRef.GuestGroup) + 
			                 NStr("en='; period '; ru='; период ';de=' Periode '") + Format(ObjectRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(ObjectRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
			Items.ParentDocDecoration.Title = TrimAll(ObjectRef);
		Else
			Title = TrimAll(ObjectRef);
			Items.ParentDocDecoration.Title = "";
		EndIf;
	EndIf;
	UpdatePanelsOnServer(True);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetChargeOrderAtServer(pCharge)
	Return Orders.GetChargeOrder(pCharge);
EndFunction // GetChargeOrderAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsLeftSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	If Item.CurrentData <> Undefined Then
		If TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Return") Then
			OpenForm("Document.Return.Form.tcDocumentForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref, , , , FormWindowOpeningMode.LockWholeInterface);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Payment") Then
			OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref, , , , FormWindowOpeningMode.LockWholeInterface);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Preauthorisation") Then
			OpenForm("Document.Preauthorisation.Form.tcDocumentForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref, , , , FormWindowOpeningMode.LockWholeInterface);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Settlement") Then
			OpenForm("Document.Settlement.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.CreditNote") Then
			OpenForm("Document.CreditNote.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.DebitNote") Then
			OpenForm("Document.DebitNote.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Charge") Then
			vCharge = Item.CurrentData.Ref;
			vOrder = GetChargeOrderAtServer(vCharge);
			If ValueIsFilled(vOrder) Then
				OpenForm("Document.Order.ObjectForm", New Structure("Key", vOrder), , vOrder);
			Else
				If ChargeIsMerged(vCharge) Then
					OpenForm("Document.Charge.Form.tcRoomRateTotalAmountCharges", New Structure("RoomRevenueCharge", vCharge), , vCharge);
				Else
					vBonusesPayment = tcOnServer.cmGetAttributeByRef(vCharge, "BonusesPayment");
					If ValueIsFilled(vBonusesPayment) Then
						OpenForm("Document.BonusesPayment.ObjectForm", New Structure("Key", vBonusesPayment), , vBonusesPayment);
					Else
						OpenForm("Document.Charge.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , vCharge);
					EndIf;
				EndIf;
			EndIf;
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.ChargeTransfer") Then
			OpenForm("Document.ChargeTransfer.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.DepositTransfer") Then
			OpenForm("Document.DepositTransfer.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		ElsIf TypeOf(Item.CurrentData.Ref) = Type("DocumentRef.Storno") Then
			OpenForm("Document.Storno.ObjectForm", New Structure("Key", Item.CurrentData.Ref), , Item.CurrentData.Ref);
		EndIf;
	EndIf;
EndProcedure // FolioDocumentsLeftSelection

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsRightSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	FolioDocumentsLeftSelection(pItem, pSelectedRow, pField, pStandardProcessing);
EndProcedure // FolioDocumentsRightSelection

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ReturnPayment(pPage)
	If IsBlankString(pPage) Then
		Return;
	EndIf;	
	
	// Check user rights
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToReturnPayments") Then
		ShowMessageBox(, NStr("en='You do not have rights to return payments!';ru='Нет прав на оформление возвратов!';de='Sie haben keine Rechte, eine Rückvergütung zu realisieren!'"));
		Return;
	EndIf;
	
	// Get preauthorisation documents selected
	vDoc  = Undefined;
	vPreauthDocs = GetPreauthorisationsSelected(pPage);
	If vPreauthDocs = 0 Then
		vCurFolio = Undefined;
		If pPage = "FolioDocumentsLeft" Then
			vCurFolio = FolioRefLeft;
		ElsIf pPage = "FolioDocumentsRight" Then  
			vCurFolio = FolioRefRight;
		EndIf;
		If Not ValueIsFilled(vCurFolio) Then
			Return;
		EndIf;
		// Process current payment
		vCurPayment = GetCurrentPayment(pPage);
		If ValueIsFilled(vCurPayment) Then
			// Check folio balance
			vDiscountCard = Undefined;
			If TypeOf(vCurPayment) <> Type("DocumentRef.DepositTransfer") Then
				vDiscountCard = tcOnServer.cmGetAttributeByRef(vCurPayment, "DiscountCard");
			EndIf;
			If Not ValueIsFilled(vDiscountCard) And Not CheckReturnFromFolioWithZeroBalance(vCurFolio) Then
				ShowMessageBox(, NStr("en='Nothing to return!'; ru='Нечего возвращать!'; de='Es gibt nichts zurückzugeben!'"));
				Return;
			EndIf;
			vDoc = vCurPayment;
		Else
			// Check folio balance
			If Not CheckReturnFromFolioWithZeroBalance(vCurFolio) Then
				ShowMessageBox(, NStr("en='Nothing to return!'; ru='Нечего возвращать!'; de='Es gibt nichts zurückzugeben!'"));
				Return;
			EndIf;
			vDoc = vCurFolio;
		EndIf;	
		OpenForm("Document.Return.Form.tcDocumentForm", New Structure("Basis, Folio", vDoc, vCurFolio), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure // ReturnPayment

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function CheckReturnFromFolioWithZeroBalance(pFolio)
	If pFolio.Hotel.PaymentsGenerateInvoices Then
		vFolioBalance = pFolio.GetObject().pmGetBalance();
		If vFolioBalance = 0 Then
			Return False;
		Else
			Return True;
		EndIf;
	Else
		Return True;
	EndIf;
EndFunction // CheckReturnFromFolioWithZeroBalance
 
// ------------------------------------------------------------------------------------------------
&AtServer
Function GetPreauthorisationsSelected(pPage)
	vCurTrans = New ValueTable();
	vCurTrans.Columns.Add("Document", , "Document", 10);
	
	vRows = GetSelectedRows(pPage);
	
	For Each vStr In vRows Do
		
		vStrData = ThisObject[pPage].FindByID(vStr);
		
		If TypeOf(vStrData.Ref)=Type("DocumentRef.Preauthorisation")  Then
			If vStrData.Ref.Status = Enums.PreauthorisationStatuses.Authorised Or 
				vStrData.Ref.Status = Enums.PreauthorisationStatuses.Archived Then
				vCurTransRow = vCurTrans.Add();
				vCurTransRow.Document = vStrData.Ref;
			EndIf;
		EndIf;	
	EndDo;
	Return vCurTrans.Count();
EndFunction //   GetPreauthorisationsSelected()

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetCurrentPayment(pPage)
	vCurDoc = Undefined;
	
	vTable = Items[pPage];	
	vStr = 	vTable.CurrentRow;	
	If vStr <> Undefined Then
		vStrData = ThisObject[pPage].FindByID(vStr);
		
		If vStrData <> Undefined Then
			If ValueIsFilled(vStrData.Ref) And 
			  (TypeOf(vStrData.Ref) = Type("DocumentRef.Payment") Or TypeOf(vStrData.Ref) = Type("DocumentRef.DepositTransfer")) Then
				vCurDoc = vStrData.Ref;
			EndIf;
		EndIf;
	EndIf;
	Return vCurDoc;
EndFunction // GetCurrentPayment

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetCurrentDoc(pPage)
	vCurDoc = Undefined;
	
	vTable = Items[pPage];	
	vStr = 	vTable.CurrentRow;	
	If vStr <> Undefined Then
		vStrData = ThisObject[pPage].FindByID(vStr);
		
		If vStrData <> Undefined Then
			Return vStrData.Ref;
		EndIf;
	EndIf;
	Return vCurDoc;
EndFunction // GetCurrentDoc

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterInputCancelActionType(pAnswer, pAdditionalParameters) Export
	If Not pAnswer = Undefined  Then
		StornoAtServer(pAdditionalParameters.ListStorno, pAnswer.TypeOfStorno, pAnswer.Remarks);
		UpdatePanelsOnServer(False, False, False);	
	EndIf;	
EndProcedure // AfterInputCancelActionType()

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterCloseFolioForm(Result, AdditionalParameters) Export
	UpdatePanelsOnServer(True);
EndProcedure

// -----------------------------------------------------------------------------
// Check if there are future reservations in chain
// -----------------------------------------------------------------------------
&AtServer
Function CheckFutureReservationsAtServer(pCurDoc, pCheckOutDate)
	vMessage = "";
	If ValueIsFilled(pCurDoc.AccommodationType) And 
	  (pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		vParentReservation = pCurDoc.GetObject().pmGetParentReservation();
		If ValueIsFilled(vParentReservation) Then
			vParentReservationObj = vParentReservation.GetObject();
			vNextReservationInChain = vParentReservationObj.pmGetNextReservationInChain();
			While ValueIsFilled(vNextReservationInChain) Do
				If ValueIsFilled(vNextReservationInChain.ReservationStatus) And vNextReservationInChain.ReservationStatus.IsActive Then
					If BegOfDay(vNextReservationInChain.CheckInDate) >= BegOfDay(pCheckOutDate) Then
						vMessage = NStr("en='Guest &Guest has active reservation period from &CheckInDate to &CheckOutDate!';
						                |ru='У гостя &Guest есть действующая бронь на период с &CheckInDate по &CheckOutDate!';
								        |de='Gast &Guest hat aktive Reservierungszeit von & CheckInDate zu &CheckOutDate!'");
						vMessage = StrReplace(vMessage, "&Guest", TrimAll(vNextReservationInChain.GuestFullName));
						vMessage = StrReplace(vMessage, "&CheckInDate", Format(vNextReservationInChain.CheckInDate, "DF=dd.MM.yyyy"));
						vMessage = StrReplace(vMessage, "&CheckOutDate", Format(vNextReservationInChain.CheckOutDate, "DF=dd.MM.yyyy"));
						Break;
					EndIf;
				Else
					Break;
				EndIf;
				vNextReservationInChain = vNextReservationInChain.GetObject().pmGetNextReservationInChain();
			EndDo;
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckFutureReservationsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddOneRoomAccommodations(pAccList, pDocRef, pInhouseOnly = False, pReversed = False)
	vOneRoomDocs = cmGetOneRoomAccommodations(pDocRef.Room, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate, pDocRef.Number);
	i = ?(pReversed, vOneRoomDocs.Count() - 1, 0);
	While True Do
		If i < 0 Or i >= vOneRoomDocs.Count() Then
			Break;
		EndIf;
		vOneRoomDocsRow = vOneRoomDocs.Get(i);
		vDocRef = vOneRoomDocsRow.Ref;
		If ValueIsFilled(vDocRef) And TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			If pAccList.FindByValue(vDocRef) = Undefined Then
				If pInhouseOnly Then
					If ValueIsFilled(vDocRef.AccommodationStatus) And 
					   Not vDocRef.AccommodationStatus.IsInHouse Then
						i = i + ?(pReversed, -1, 1);
						Continue;
					EndIf;
				EndIf;
				pAccList.Add(vDocRef);
			EndIf;
		EndIf;
		i = i + ?(pReversed, -1, 1);
	EndDo;
EndProcedure // AddOneRoomAccommodations

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CheckIfCheckOutDateTimeIsFilled() 
	If ValueIsFilled(CheckOutDateTime) And ValueIsFilled(MainRoomDoc) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		// Check future reservations
		vMessage = CheckFutureReservationsAtServer(MainRoomDoc, CheckOutDateTime);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
		// Do check-out
		vResult = CheckOutAtServer(MainRoomDoc, AccList, CheckOutDateTime, False);
		If ValueIsFilled(vResult) Then
			If vResult = "SendNotifications" Then
				// Send notification to all open forms
				Notify("Subsystem.Accounts.Changed", MainRoomDoc, ThisObject);
				Notify("Document.ResourceReservation.Write", , ThisObject);
				// Notify that accommodation is changed
				Notify("Document.Accommodation.Write", MainRoomDoc, ThisObject);
			Else
				ShowMessageBox(, vResult);
			EndIf;
		Else
			// Notify that accommodation is changed
			Notify("Document.Accommodation.Write", MainRoomDoc, ThisObject);
		EndIf;
		OnReopen();
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

// ------------------------------------------------------------------------------------------------
&AtServer
Function CheckOutAtServer(pRef, pAccList, pCheckOutDate, pFixReservationConditions)
	vResult = "";
	vCurRoom = Undefined;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vAccItem In pAccList Do
			vAccDoc = vAccItem.Value;
			// Commit transaction if room has changed
			If vCurRoom <> Undefined And vCurRoom <> vAccDoc.Room Then
				If TransactionActive() Then
					CommitTransaction();
					// Start transaction
					BeginTransaction(DataLockControlMode.Managed);
				EndIf;
			EndIf;
			If vCurRoom <> vAccDoc.Room Then
				vCurRoom = vAccDoc.Room;
			EndIf;
			// Process document
			If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
				vSkipDocument = False;
				If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
					vCheckOutDate = vAccDoc.CheckOutDate;
					If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
						vSkipDocument = True;
					EndIf;
				EndIf;
				If Not vSkipDocument Then
					// Do check-out
					vAccObj = vAccDoc.GetObject();
					If pFixReservationConditions Then
						vAccObj.FixReservationConditions = pFixReservationConditions;
					EndIf;
					vAccObj.pmCheckOut(pCheckOutDate, , vAccObj.IsForFolioSplit);
					vAccObj.Write(DocumentWriteMode.Posting);
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					// Hide client name data if necessary
					If vAccObj.pmHideClientNameAndNameHistory() Then
						vResult = "SendNotifications";
					EndIf;
				EndIf;
			Else
				Raise NStr("ru='Отметили в списке размещений для выселения не проведенное размещение! Процедура выселения возможна только для проведенных размещений. Операция отменена.';
				|de='Sie haben in der Unterbringungsliste für die Räumung einer nicht erfolgten Unterbringung markiert! Die Räumung ist nur für erfolgte Unterbringungen möglich. Die Operation wurde abgebrochen.'; 
				|en='You have selected not posted accommodation for check out! Check out procedure is possible for posted accommodations only. Operation is canceled.'");
			EndIf;
			
			// Check if rooms are the same
			If vAccDoc.Room <> vCurRoom Then
				vCurRoom = Undefined;
			EndIf;
		EndDo;
		If TransactionActive() Then
			CommitTransaction();
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		Try
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		Except
		EndTry;
		WriteLogEvent(NStr("en='Accommodation.CheckOut';ru='Размещение.Выселение';de='Accommodation.CheckOut'"), EventLogLevel.Warning, pRef.Metadata(), pRef, cmGetRootErrorDescription(vErrInfo));
		// Try to save current accommodation with in-house state
		vErrorDescription = cmGetRootErrorDescription(vErrInfo);
		vResult = vErrorDescription;
		If (Find(vErrorDescription, "CHECKOUT_WITH_DEBT") > 0 Or Find(vErrorDescription, "ADVANCES_NOT_CLEARED") > 0) And 
		   vAccDoc <> Undefined Then
			Try
				BeginTransaction(DataLockControlMode.Managed);
				// Do change check-out date and time
				vCurRoom = vAccDoc.Room;
				For Each vAccItem In pAccList Do
					vAccDoc = vAccItem.Value;
					If vCurRoom = vAccDoc.Room Then
						If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
							vSkipDocument = False;
							If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
								vCheckOutDate = vAccDoc.CheckOutDate;
								If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
									vSkipDocument = True;
								EndIf;
							EndIf;
							If Not vSkipDocument Then
								vAccObj = vAccDoc.GetObject();
								If pFixReservationConditions Then
									vAccObj.FixReservationConditions = pFixReservationConditions;
								EndIf;
								vAccObj.CheckOutDate = pCheckOutDate;
								// Calculate duration
								vAccObj.Duration = vAccObj.pmCalculateDuration();
								// Automatic services list calculation
								vAccObj.pmCalculateServices(, , , , , vAccObj.IsForFolioSplit);
								vAccObj.Write(DocumentWriteMode.Posting);
								vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If TransactionActive() Then
					CommitTransaction();
				EndIf;
			Except
				Try
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
				Except
				EndTry;
			EndTry;
		EndIf;
	EndTry;
	Return vResult;
EndFunction // CheckOutAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Function ExtractTime(pDateTime)
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // ExtractTime

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetMainDocRef(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Guest AS GuestRef
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGroup
	|	AND (Accommodation.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Accommodation.Number = &qNumber
	|				AND NOT &qRoomIsFilled)
	|	AND Accommodation.Posted
	|	AND NOT Accommodation.DeletionMark
	|	AND ((Accommodation.AccommodationStatus.IsActive
	|			OR Accommodation.AccommodationStatus.IsCheckIn)
	|		OR	(Accommodation.AccommodationStatus = &qAccStatus))
	|ORDER BY
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qAccStatus", pRef.AccommodationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRef

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDate(pCheckInDate, pCheckOutDate)
	vCheckOutDateTime = CurrentDate();
	If vCheckOutDateTime < pCheckInDate Then
		vCheckOutDateTime = pCheckInDate;
	EndIf;
	vFrm = GetForm("CommonForm.tcInputDateTime");
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseReferenceHourAsDefaultCheckOutTime") Then
		vFrm.Date = BegOfDay(CurrentDate());
		If BegOfDay(pCheckOutDate) = BegOfDay(CurrentDate()) Then
			If CurrentDate() < pCheckOutDate Then
				vFrm.Time = ExtractTime(CurrentDate());
			Else
				vFrm.Time = ExtractTime(pCheckOutDate);
			EndIf;
		Else
			vFrm.Time = ExtractTime(pCheckOutDate);
		EndIf;
	Else
		vFrm.Date = BegOfDay(CurrentDate());
		vFrm.Time = ExtractTime(CurrentDate());
	EndIf;
	vFrm.Description = NStr("en = 'Check-out time:'; de = 'Abreisezeit:'; ru = 'Время выселения:'");
	vFrm.Title = vFrm.Description;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
		vFrm.IsProtected = True;
	EndIf;
	vFrm.OnCloseNotifyDescription = New NotifyDescription("GetCheckOutDateAfterUserInput", ThisObject, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate));
	vFrm.Open();
EndProcedure // GetCheckOutDate

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDateAfterUserInput(pCheckOutDateTime, pExtraParameters) Export
	CheckOutDateTime = '00010101';
	// Check check out date and time entered
	If Not ValueIsFilled(pCheckOutDateTime) Then
		ShowMessageBox(, NStr("ru='Процедура выселения отменена!';
		                      |de='Das Ausweisungsverfahren wurde abgebrochen'; 
		                      |en='Check-out procedure is canceled!'"));
		Return;
	EndIf;
	If pCheckOutDateTime < pExtraParameters.CheckInDate Then
		ShowMessageBox(, NStr("ru='Ввели дату и время выселения, которые раньше чем дата и время заезда!';
		                      |de='Sie haben ein Abreisedatum und eine Abreisezeit eingegeben, die vor dem Anreisedatum und der Anreisezeit liegen!'; 
		                      |en='You have entered check-out date and time that are earlier then check-in date and time!'"));
		Return;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
		vAllowedCheckOutDelayTime = 1;
		If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute()) Then
			vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(tcOnServer.cmGetCurrentUserAttribute());
			If ValueIsFilled(vPermissionGroup) Then
				If tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime") > 0 Then
					vAllowedCheckOutDelayTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime");
				EndIf;
			EndIf;
		EndIf;
		vTimeDiff = Round((CurrentDate() - pCheckOutDateTime) / 3600, 3);
		If vTimeDiff > vAllowedCheckOutDelayTime Then
			ShowMessageBox(, NStr("ru='Ввели дату выселения в прошлом. Есть права на выселение только текущей или будущей датой!';
			                      |de='Sie haben ein Räumungsdatum angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
			                      |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			Return;
		EndIf;
	EndIf;
	CheckOutDateTime = pCheckOutDateTime;
EndProcedure // GetCheckOutDateAfterUserInput

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function NeedToPrintReceipt(rPrtForm)
	rPrtForm = Catalogs.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges;
	If rPrtForm.IsActive And rPrtForm.AutomaticallyPrintOnFirstObjectWrite Then
		Return True;
	EndIf;
	Return False;
EndFunction // NeedToPrintReceipt

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetReceiptPrintSettings(pPrtForm)
	vWidth = 30;
	vFilter = "";
	vCopies = 1;
	If ValueIsFilled(pPrtForm) Then
		If pPrtForm.Width <> 0 Then
			vWidth = pPrtForm.Width;
		EndIf;
		If pPrtForm.Copies <> 0 Then
			vCopies = pPrtForm.Copies;
		EndIf;
		If Not IsBlankString(pPrtForm.Parameter) Then
			vFilter = Upper(TrimAll(pPrtForm.Parameter));
		EndIf;
	EndIf;
	vFormPrintSettings = New Structure("ReceiptWidth, FooterText, CashRegister, PrintDirection, PrinterName, FitToPage, PrintScale, Copies, CopiesPerPage, Collate, PageOrientation, PageSize, TopMargin, BottomMargin, LeftMargin, RightMargin, HeaderSize, FooterSize, BlackAndWhite, Filter, DuplexPrintingType", 
	                                   vWidth, "en='All taxes included'; ru='Все налоги включены'; de='Alle Steuern inklusive'", Undefined, Undefined, "", True, 0, vCopies, 1, False, Undefined, "", 0, 0, 0, 0, 0, 0, False, vFilter, Undefined);
	vWstnSettings = SessionParameters.CurrentWorkstation;
	If vWstnSettings.CashRegisters.Count() > 0 Then
		For Each vCRRow In vWstnSettings.CashRegisters Do
			If ValueIsFilled(vCRRow.CashRegister) And vCRRow.CashRegister.IsControlledByProgram Then
				vFormPrintSettings.CashRegister = vCRRow.CashRegister;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(vWstnSettings.WorkstationPrintSettings) Then
		vWstnPrintSettings = vWstnSettings.WorkstationPrintSettings;
		vPrtFrmSettingsRow = vWstnPrintSettings.PrintFormsList.Find(pPrtForm, "ObjectPrintingForm");
		If vPrtFrmSettingsRow <> Undefined And vPrtFrmSettingsRow.IsActive Then
			FillPropertyValues(vFormPrintSettings, vPrtFrmSettingsRow);
		EndIf;
	EndIf;
	Return vFormPrintSettings;
EndFunction // GetReceiptPrintSettings

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetChequeRowAtServer(pDocRef, pFolio, pLanguage, rSum, rVATRate)
	vTxt = "";
	rSum = 0;
	rVATRate = Undefined;
	If TypeOf(pDocRef) = Type("DocumentRef.Charge") Then
		rVATRate = pDocRef.VATRate;
		rSum = pDocRef.Sum - pDocRef.DiscountSum;
		vTxt = pDocRef.Service.GetObject().pmGetServiceDescription(pLanguage) + 
		       " x " + Format(pDocRef.Quantity, "NFD=3; NZ=; NG=") + 
		       " = " + Format(rSum, "NFD=2");
		If Not IsBlankString(pDocRef.Remarks) Then
			vTxt = vTxt + Chars.LF + "  " + TrimAll(pDocRef.Remarks);
		EndIf;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.Payment") Then
		If pDocRef.PaymentSections.Count() > 0 And ValueIsFilled(pDocRef.PaymentSections.Get(0).ChequeService) Then
			For Each vDocRefPSRow In pDocRef.PaymentSections Do
				vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + 
				       vDocRefPSRow.ChequeService.GetObject().pmGetServiceDescription(pLanguage) + Chars.LF + 
					   " " + Format(vDocRefPSRow.ChequeServicePrice, "NFD=2") + " x " + Format(vDocRefPSRow.ChequeServiceQuantity, "NFD=3") + " = " + Format(vDocRefPSRow.Sum, "NFD=2");
			EndDo;
			vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + "------------------------"; 
		EndIf;
		rVATRate = pDocRef.VATRate;
		rSum = pDocRef.Sum;
		vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + pDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage) + 
		       " = " + Format(rSum, "NFD=2");
		If Not IsBlankString(pDocRef.Remarks) Then
			vTxt = vTxt + Chars.LF + "  " + TrimAll(pDocRef.Remarks);
		EndIf;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.Return") Then
		If pDocRef.PaymentSections.Count() > 0 And ValueIsFilled(pDocRef.PaymentSections.Get(0).ChequeService) Then
			For Each vDocRefPSRow In pDocRef.PaymentSections Do
				vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + 
				       vDocRefPSRow.ChequeService.GetObject().pmGetServiceDescription(pLanguage) + Chars.LF + 
					   " " + Format(vDocRefPSRow.ChequeServicePrice, "NFD=2") + " x " + Format(vDocRefPSRow.ChequeServiceQuantity, "NFD=3") + " = " + Format(vDocRefPSRow.Sum, "NFD=2");
			EndDo;
			vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + "------------------------"; 
		EndIf;
		rVATRate = pDocRef.VATRate;
		rSum = pDocRef.Sum;
		vTxt = vTxt + ?(IsBlankString(vTxt), "", Chars.LF) + cmNStr("en='Refund '; ru='Возврат '; de='Rückzahlung '", pLanguage) + " " + 
		       pDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage) + 
		       " = " + Format(rSum, "NFD=2");
		If Not IsBlankString(pDocRef.Remarks) Then
			vTxt = vTxt + Chars.LF + "  " + TrimAll(pDocRef.Remarks);
		EndIf;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.Storno") Then
		vCharge = pDocRef.ParentCharge;
		rVATRate = vCharge.VATRate;
		rSum = -(vCharge.Sum - vCharge.DiscountSum);
		vTxt = cmNStr("en='Cancel '; ru='Сторно '; de='Stornierung '", pLanguage) + " " + 
		       vCharge.Service.GetObject().pmGetServiceDescription(pLanguage) + 
		       " x " + Format(vCharge.Quantity, "NFD=3; NZ=; NG=") + 
		       " = " + Format(rSum, "NFD=2");
		If Not IsBlankString(pDocRef.Remarks) Then
			vTxt = vTxt + Chars.LF + "  " + TrimAll(pDocRef.Remarks);
		EndIf;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.DepositTransfer") Then
		vFolioFrom = pDocRef.FolioFrom;
		vFolioTo = pDocRef.FolioTo;
		If pFolio = vFolioFrom Then
			vCompany = vFolioFrom.Company;
			rVATRate = vCompany.VATRate;
			rSum = -pDocRef.SumInFolioFromCurrency;
		Else
			vCompany = vFolioTo.Company;
			rVATRate = vCompany.VATRate;
			rSum = pDocRef.SumInFolioToCurrency;
		EndIf;
		vTxt = pDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage) + 
		       " = " + Format(rSum, "NFD=2");
		If Not IsBlankString(pDocRef.Remarks) Then
			vTxt = vTxt + Chars.LF + "  " + TrimAll(pDocRef.Remarks);
		EndIf;
	EndIf;
	Return vTxt;
EndFunction // GetChequeRowAtServer
 
// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PrintReceipt(pFolio, pLanguage, pTransArray, pFormPrintSettings)
	If pTransArray.Count() = 0 Then
		Return;
	EndIf;
	
	// Check printer to be used
	If IsBlankString(pFormPrintSettings.PrinterName) And ValueIsFilled(pFormPrintSettings.CashRegister) Then
		// Print non fiscal cheque via cash register printer
		vDriver = tcOnClient.cmGetModulTO(pFormPrintSettings.CashRegister);
		If Not vDriver = Undefined Then
			vChequeSum = 0;
			vVATRate = Undefined;
			vFolioCurrency = tcOnServer.cmGetAttributeByRef(pFolio, "FolioCurrency");
			vAuthor = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			vFilter = pFormPrintSettings.Filter;
			vShowPaymentsOnly = False;
			If StrFind(Upper(vFilter), "SHOW_PAYMENTS_ONLY") > 0 Then
				vShowPaymentsOnly = True;
			EndIf;
			
			vIsPayment = False;
			vDocRef = Undefined;
			If TypeOf(vDocRef) = Type("DocumentRef.Payment") Or TypeOf(vDocRef) = Type("DocumentRef.Return") Then
				vIsPayment = True;
			EndIf;
			If vShowPaymentsOnly Then
				If Not vIsPayment Then
					Return;
				EndIf;
			EndIf;
			
			// Cheque template
			vChequeText = 
			Upper(NStr("en='Receipt'; ru='Квитанция'; de='Quittung'")) + "
			|&CurrentDate &CurrentTime
			|&Cashier
			|&FolioHeader
			|--------------------------------------------------------------------------------
			|" + ?(vIsPayment, Upper(NStr("en='Payment:'; ru='Оплата:'; de='Zahlung:'")), Upper(NStr("en='Services:'; ru='Услуги:'; de='Dienstleistungen:'")));
			For Each vDocRef In pTransArray Do
				vRowSum = 0;
				vRowTxt = GetChequeRowAtServer(vDocRef, pFolio, pLanguage, vRowSum, vVATRate);
				vChequeText = vChequeText + Chars.LF + vRowTxt;
				
				vChequeSum = vChequeSum + vRowSum;
			EndDo;
			vChequeText = vChequeText + Chars.LF + "--------------------------------------------------------------------------------";
			If vChequeSum <> 0 Then
				vChequeText = vChequeText + Chars.LF + NStr("en='TOTAL '; ru='ИТОГО '; de='TOTAL '") + Format(vChequeSum, "NFD=2") + " &Currency";
			EndIf;
			vChequeText = vChequeText + Chars.LF + "&Cliche";
			
			vCopies = ?(pFormPrintSettings.Copies = 0, 1, pFormPrintSettings.Copies);
			
			For i = 1 To vCopies Do
				vMessage = "";
				vStruct = New Structure("Sum, VATSum, CashRegister, Folio, VATRate, Author, PaymentCurrency", vChequeSum, 0, pFormPrintSettings.CashRegister, pFolio, vVATRate, vAuthor, vFolioCurrency);
				If Not vDriver.pmPrintNonFiscalCheque(vStruct.Sum, vStruct.VATSum, vStruct, vChequeText, vMessage) Then
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				EndIf;
			EndDo;
		EndIf;
	ElsIf Not IsBlankString(pFormPrintSettings.PrinterName) Then
		// Print receipt on windows printer
		vBatch = New RepresentableDocumentBatch();
		
		vReceiptAddress = GetReceiptAtServer(pFolio, pLanguage, pTransArray, pFormPrintSettings);
		If vReceiptAddress <> Undefined Then
			vBatch.Content.Add(vReceiptAddress);
			
			vBatch.Collate = pFormPrintSettings.Collate;
			vBatch.Copies = ?(pFormPrintSettings.Copies = 0, Undefined, pFormPrintSettings.Copies);
			vBatch.PrinterName = TrimAll(pFormPrintSettings.PrinterName);
			
			vBatch.Print(?(IsBlankString(TrimAll(pFormPrintSettings.PrinterName)), PrintDialogUseMode.Use, PrintDialogUseMode.DontUse));
		EndIf;
	EndIf;
EndProcedure // PrintReceipt	

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetReceiptAtServer(pFolio, pLanguage, pTransArray, pFormPrintSettings)
	vOperationName = "en='Receipt'; ru='Квитанция'; de='Quittung'";
	vCompanyObj = pFolio.Company.GetObject();
	vDocRef = pTransArray.Get(0);
	
	vReceipt = New TextDocument();
	
	vReceiptTemplateName = "Receipt" + Format(pFormPrintSettings.ReceiptWidth, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vReceiptTemplate = Documents.Folio.GetTemplate(vReceiptTemplateName);
	
	vTextReceiptTemplateName = vReceiptTemplateName + TrimAll(pLanguage.Code);
	Try
		vTextReceiptTemplate = Documents.Folio.GetTemplate(vTextReceiptTemplateName);
	Except
		Return Undefined;
	EndTry;
	
	vReceiptHeaderArea = vTextReceiptTemplate.GetArea("ReceiptHeader");
	vReceiptHeaderArea.Parameters.Company = vCompanyObj.pmGetCompanyPrintName(pLanguage);
	vReceiptHeaderArea.Parameters.Address = vCompanyObj.pmGetCompanyPostAddressPresentation(pLanguage);
	vReceiptHeaderArea.Parameters.Codes = vCompanyObj.pmGetCompanyIdentificationCodes(pLanguage);
	vReceiptHeaderArea.Parameters.Operation = Upper(cmNStr(vOperationName, pLanguage));
	vReceiptHeaderArea.Parameters.ReceiptN = cmGetDocumentNumberPresentation(vDocRef.Number);
	vReceiptHeaderArea.Parameters.Cashier = TrimAll(SessionParameters.CurrentUser);
	vReceiptHeaderArea.Parameters.Date = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	vReceiptHeaderArea.Parameters.Time = Format(CurrentSessionDate(), "DF=HH:mm:ss");
	vReceipt.Put(vReceiptHeaderArea);
	
	vTotalAmount = 0;
	
	For Each vDocRef In pTransArray Do
		If TypeOf(vDocRef) = Type("DocumentRef.Charge") Then
			vRowSum = vDocRef.Sum - vDocRef.DiscountSum;
			vReceiptDebitRowArea = vTextReceiptTemplate.GetArea("ReceiptDebitRow");
			vReceiptDebitRowArea.Parameters.OperationDescription = vDocRef.Service.GetObject().pmGetServiceDescription(pLanguage);
			If Not IsBlankString(vDocRef.Remarks) Then
				vReceiptDebitRowArea.Parameters.OperationDescription = vReceiptDebitRowArea.Parameters.OperationDescription + " - " + TrimAll(vDocRef.Remarks);
			EndIf;
			vReceiptDebitRowArea.Parameters.Quantity = Format(vDocRef.Quantity, "NFD=3; NZ=");
			vReceiptDebitRowArea.Parameters.Amount = Format(vRowSum, "NFD=2; NZ=");
			vReceiptDebitRowArea.Parameters.Price = Format(Round(vRowSum / ?(vDocRef.Quantity = 0, 1, vDocRef.Quantity), 2), "NFD=2; NZ=");
			vReceipt.Put(vReceiptDebitRowArea);
			vTotalAmount = vTotalAmount + vRowSum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Storno") Then
			vChargeRef = vDocRef.ParentCharge;
			vRowSum = -(vChargeRef.Sum - vChargeRef.DiscountSum);
			vReceiptDebitRowArea = vTextReceiptTemplate.GetArea("ReceiptDebitRow");
			vReceiptDebitRowArea.Parameters.OperationDescription = cmNStr("en='Cancel '; ru='Сторно '; de='Stornierung '", pLanguage) + " " + 
			                                                       vChargeRef.Service.GetObject().pmGetServiceDescription(pLanguage);
			vReceiptDebitRowArea.Parameters.Quantity = Format(vChargeRef.Quantity, "NFD=3; NZ=");
			vReceiptDebitRowArea.Parameters.Amount = Format(vRowSum, "NFD=2; NZ=");
			vReceiptDebitRowArea.Parameters.Price = Format(Round(?(vRowSum < 0, -vRowSum, vRowSum) / ?(vDocRef.Quantity = 0, 1, ?(vDocRef.Quantity < 0, -vDocRef.Quantity, vDocRef.Quantity)), 2), "NFD=2; NZ=");
			vReceipt.Put(vReceiptDebitRowArea);
			vTotalAmount = vTotalAmount + vRowSum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Payment") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			If Not IsBlankString(vDocRef.Remarks) Then
				vReceiptCreditRowArea.Parameters.OperationDescription = vReceiptCreditRowArea.Parameters.OperationDescription + " - " + TrimAll(vDocRef.Remarks);
			EndIf;
			vReceiptCreditRowArea.Parameters.Amount = Format(vDocRef.Sum, "NFD=2; NZ=");
			vReceipt.Put(vReceiptCreditRowArea);
			vTotalAmount = vTotalAmount + vDocRef.Sum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Return") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = cmNStr("en='Refund '; ru='Возврат '; de='Rückzahlung '", pLanguage) + " " + 
			                                                        vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			vReceiptCreditRowArea.Parameters.Amount = Format(-vDocRef.Sum, "NFD=2; NZ=");
			vReceipt.Put(vReceiptCreditRowArea);
			vTotalAmount = vTotalAmount - vDocRef.Sum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.DepositTransfer") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			If pFolio = vDocRef.FolioFrom Then
				vReceiptCreditRowArea.Parameters.Amount = Format(-vDocRef.SumInFolioFromCurrency, "NFD=2; NZ=");
				vTotalAmount = vTotalAmount - vDocRef.SumInFolioFromCurrency;
			Else
				vReceiptCreditRowArea.Parameters.Amount = Format(vDocRef.SumInFolioToCurrency, "NFD=2; NZ=");
				vTotalAmount = vTotalAmount + vDocRef.SumInFolioToCurrency;
			EndIf;
			vReceipt.Put(vReceiptCreditRowArea);
		EndIf;
	EndDo;
		
	vReceiptTotalArea = vTextReceiptTemplate.GetArea("ReceiptTotal");
	vReceiptTotalArea.Parameters.TotalAmount = Format(vTotalAmount, "NFD=2; NZ=");
	vReceipt.Put(vReceiptTotalArea);
		
	vReceiptFooterArea = vTextReceiptTemplate.GetArea("ReceiptFooter");
	If ValueIsFilled(pFolio.Client) Then
		vReceiptFooterArea.Parameters.Client = TrimAll(pFolio.Client.FullName);
	Else
		vReceiptFooterArea.Parameters.Client = "";
	EndIf;
	If ValueIsFilled(pFolio.Room) Then
		vReceiptFooterArea.Parameters.Room = TrimAll(pFolio.Room.Description);
	Else
		vReceiptFooterArea.Parameters.Room = "";
	EndIf;
	vReceiptFooterArea.Parameters.FooterText = cmNStr(pFormPrintSettings.FooterText, pLanguage);
	vReceipt.Put(vReceiptFooterArea);
	
	vReceiptText = vReceipt.GetText();
	vTextRowsArray = cmGetTextLinesArray(vReceiptText);
	
	vReceiptSpreadsheet = New SpreadsheetDocument();
	For Each vTextRow In vTextRowsArray Do
		vReceiptRowArea = vReceiptTemplate.GetArea("ReceiptRow");
		vReceiptRowArea.Parameters.RowText = vTextRow;
		vReceiptSpreadsheet.Put(vReceiptRowArea);
	EndDo;
	
	vTempAddress = PutToTempStorage(vReceiptSpreadsheet);
	
	Return vTempAddress;
EndFunction // GetReceiptAtServer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetLanguageByFolio(pFolio)
	vLanguage = Catalogs.Languages.Ru;
	If ValueIsFilled(pFolio) Then
		If ValueIsFilled(pFolio.Client) And ValueIsFilled(pFolio.Client.Language) Then
			vLanguage = pFolio.Client.Language;
		ElsIf ValueIsFilled(pFolio.Customer) And ValueIsFilled(pFolio.Customer.Language) Then
			vLanguage = pFolio.Customer.Language;
		ElsIf ValueIsFilled(pFolio.Hotel) And ValueIsFilled(pFolio.Hotel.Language) Then
			vLanguage = pFolio.Hotel.Language;
		EndIf;
	EndIf;
	Return vLanguage;
EndFunction // GetLanguageByFolio

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure RefreshTransactionsLists() Export
	If IsInputAvailable() Then
		// Refresh list
		UpdatePanelsOnServer(True, False, False);
	Else
		AttachIdleHandler("RefreshTransactionsLists", 1, True);
	EndIf;
EndProcedure // RefreshTransactionsLists

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillListOfObjectPrintingForms()
	If SelValueListButton.Count() > 0 Then
		For Each vInd In SelValueListButton Do
			vButton = Items.Find(vInd.Value);
			If TypeOf(vButton) = Type("FormButton") Then
				Items.Delete(vButton);
			EndIf;	
		EndDo;
	EndIf;	
	If FolioList.Count() = 0 Then
		Return;
	EndIf;
	
	// Get list of folio printing forms
	CurFolio = FolioList.Get(0).Value;
	vLang = Catalogs.Languages.EmptyRef();
	If ValueIsFilled(CurFolio.Client) Then
		If ValueIsFilled(CurFolio.Client.Language) Then
			vLang = CurFolio.Client.Language;
		EndIf;
	ElsIf ValueIsFilled(CurFolio.Customer) Then
		vLang = CurFolio.Customer.Language;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	vQuery.SetParameter("ObjectType", Documents.Folio.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	
	// 1.Fill left panel
	// Add command
	If FolioList.Count() = 1 Then
		vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
		While vSelectionRecords.Next() Do
			vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
			
			If vLang = vSelectionRecords.Language Or not ValueIsFilled(vSelectionRecords.Language) Then
				vParentLang = Items.FormGroupPrintingNotDefaultMainLeft;
			ElsIf Not vLang = vSelectionRecords.Language Then
				vParentLang = Items.Find("FormGroupPrint" + vSelectionRecords.Language + "Left"); 
				If vParentLang = Undefined Then
					vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraLeft, "Print" + vSelectionRecords.Language + "Left", "FormGroup",
														  New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
				EndIf;
			EndIf;
			
			While vSelectionDetailRecords.Next() Do	
				vObjectPrintingForm = vSelectionDetailRecords.Ref;
				vCommandName 	= vObjectPrintingForm.PredefinedDataName; 
				vPredName 		= "";
				If vCommandName = "" Then
					vPredName 	 = String(vObjectPrintingForm.UUID());
					vCommandName = "FolioDocumentsLeft" + StrReplace(vPredName, "-", "");
				Else
					vCommandName = "FolioDocumentsLeft" + vObjectPrintingForm.PredefinedDataName;
				EndIf;

				If Commands.Find(vCommandName) = Undefined  Then
					vCommand = Commands.Add(vCommandName);
					vCommand.Action = "Print";
					SelValueListButton.Add(vCommandName, vPredName);
				EndIf;
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefaultLeft;
				Else
					vParent = vParentLang;
				EndIf;
				
				// Add button
				vItem = Items.Add(vCommandName, Type("FormButton"), vParent);
				vItem.Title = TrimAll(vObjectPrintingForm.Code) + " " + tcOnServer.cmNStrAtServer(vObjectPrintingForm.Description);
				vItem.Type = FormButtonType.UsualButton;
				vItem.CommandName = vCommandName; 
			EndDo;
		EndDo;
	ElsIf FolioList.Count() > 1 Then
		vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
		While vSelectionRecords.Next() Do
			vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
			
			If vLang = vSelectionRecords.Language Or Not ValueIsFilled(vSelectionRecords.Language) Then
				vParentLang = Items.FormGroupPrintingNotDefaultMainLeft;
			ElsIf Not vLang = vSelectionRecords.Language Then
				vParentLang = Items.Find("FormGroupPrint" + vSelectionRecords.Language + "Left"); 
				If vParentLang = Undefined Then
					vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraLeft, "Print" + vSelectionRecords.Language + "Left", "FormGroup",
					                                      New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
				EndIf;
			EndIf;
			
			While vSelectionDetailRecords.Next() Do	
				vObjectPrintingForm = vSelectionDetailRecords.Ref;
				vCommandName 	= vObjectPrintingForm.PredefinedDataName; 
				vPredName 		= "";
				If vCommandName = "" Then
					vPredName 	 = String(vObjectPrintingForm.UUID());
					vCommandName = "FolioDocumentsLeft" + StrReplace(vPredName, "-", "");
				Else
					vCommandName = "FolioDocumentsLeft" + vObjectPrintingForm.PredefinedDataName;
				EndIf;

				If Commands.Find(vCommandName) = Undefined  Then
					vCommand = Commands.Add(vCommandName);
					vCommand.Action = "Print";
					SelValueListButton.Add(vCommandName, vPredName);
				EndIf;
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefaultLeft;
				Else
					vParent = vParentLang;
				EndIf;
				
				// Add button
				vItem = Items.Add(vCommandName, Type("FormButton"), vParent);
				vItem.Title = TrimAll(vObjectPrintingForm.Code) + " " + tcOnServer.cmNStrAtServer(vObjectPrintingForm.Description);
				vItem.Type = FormButtonType.UsualButton;
				vItem.CommandName = vCommandName; 
			EndDo;
		EndDo;
		
		// 2.Fill right panel
		CurFolio = FolioList.Get(1).Value;
		vLang = Catalogs.Languages.EmptyRef();
		If ValueIsFilled(CurFolio.Client) Then
			If ValueIsFilled(CurFolio.Client.Language) Then
				vLang = CurFolio.Client.Language;
			EndIf;
		ElsIf ValueIsFilled(CurFolio.Customer) Then
			vLang = CurFolio.Customer.Language;
		EndIf;
		
		vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
		While vSelectionRecords.Next() Do
			vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
			
			If vLang = vSelectionRecords.Language Or Not ValueIsFilled(vSelectionRecords.Language) Then
				vParentLang = Items.FormGroupPrintingNotDefaultMainRight;
			ElsIf Not vLang = vSelectionRecords.Language Then                   
				vParentLang = Items.Find("FormGroupPrint" + vSelectionRecords.Language + "Right"); 
				If vParentLang = Undefined Then
					vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraRight, "Print" + vSelectionRecords.Language + "Right", "FormGroup",
														  New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
				EndIf;
			EndIf;
			
			While vSelectionDetailRecords.Next() Do	
				vObjectPrintingForm = vSelectionDetailRecords.Ref;
				vCommandName 	= vObjectPrintingForm.PredefinedDataName; 
				vPredName 		= "";
				If vCommandName = "" Then
					vPredName 	 = String(vObjectPrintingForm.UUID());
					vCommandName = "FolioDocumentsRight"+StrReplace(vPredName,"-","");
				Else
					vCommandName = "FolioDocumentsRight"+vObjectPrintingForm.PredefinedDataName;
				EndIf;

				If Commands.Find(vCommandName) = Undefined  Then
					vCommand = Commands.Add(vCommandName);
					vCommand.Action = "Print";
					SelValueListButton.Add(vCommandName, vPredName);
				EndIf;
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefaultRight;
				Else
					vParent = vParentLang;
				EndIf;
				
				// Add button
				vItem = Items.Add(vCommandName, Type("FormButton"), vParent);
				vItem.Title = TrimAll(vObjectPrintingForm.Code) + " " + tcOnServer.cmNStrAtServer(vObjectPrintingForm.Description);
				vItem.Type = FormButtonType.UsualButton;
				vItem.CommandName = vCommandName; 
			EndDo;
		EndDo;
	EndIf;
EndProcedure // FillListOfObjectPrintingForms

// ------------------------------------------------------------------------------------------------
&AtServer
Function  GetPrintFormTypeRef(pItem, pCommandName)
	vMessage = NStr("en = 'Failed to get the printed form'; ru = 'Ошибка получения печатной формы'; de = 'Konnte die gedruckte Form zu erhalten'");
	vFnd = SelValueListButton.FindByValue(pCommandName);
	If vFnd.Presentation = "" Then
		Try
			vObjectPrintingForm = Catalogs.ObjectPrintingForms[pItem];
		Except
			Raise vMessage;
		EndTry;
		If Not vObjectPrintingForm = Undefined And Not vObjectPrintingForm.IsEmpty() Then
			Return vObjectPrintingForm;
		EndIf;
	Else
		Try
			GUID = New UUID(vFnd.Presentation);
			vObjectPrintingForm = Catalogs.ObjectPrintingForms.GetRef(GUID);
		Except
			Raise NStr("en = 'Failed to get the printed form'; ru = 'Ошибка получения печатной формы'; de = 'Konnte die gedruckte Form zu erhalten'");
		EndTry;
		If Not vObjectPrintingForm = Undefined And Not vObjectPrintingForm.IsEmpty() Then
			Return vObjectPrintingForm;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
EndFunction

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pFolio, pTransactions)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, "ExternalPrintFolioForm");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Transactions", pFolio, pPrintFormTypeRef, pTransactions);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// ------------------------------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pDocRef, pTransactions)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm, Transactions", pDocRef, pPrintFormTypeRef, pTransactions);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure SendOnlineCheque(pCurData)
	vCurDocRef = Undefined;
	If pCurData <> Undefined Then
		If TypeOf(pCurData.Ref) = Type("DocumentRef.Return") Or TypeOf(pCurData.Ref) = Type("DocumentRef.Payment") Then
			vCurDocRef = pCurData.Ref;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCurDocRef) Then
		ShowMessageBox(, NStr("en='Choose payment or refund!'; ru='Выберите платеж или возврат!'; de='Wählen Sie eine Zahlung oder eine Rückerstattung!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurDocRef, "CashRegister")) Then
		ShowMessageBox(, NStr("en='Cash register is empty!'; ru='Не указан ККМ!'; de='Kasse ist leer!'"));
		Return;
	EndIf;
	OpenForm("Catalog.CashRegisters.Form.tcSendOnlineCheque", New Structure("Payment", vCurDocRef), ThisObject, vCurDocRef, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SendOnlineCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure MakeKey(pDocRef)
	vParametersKeyCard = tcOnServer.cmFillParametersKeyCard(pDocRef);
	vParams = New Structure();
	vParams.Insert("ParametersKeyCard", vParametersKeyCard);
	vCurWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	OpenForm("CommonForm.tcIssueKeyCard", vParams, ThisObject, vCurWorkstation, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // MakeKey

// -----------------------------------------------------------------------------
&AtServer
Function GetIdentityCardParameters(pFolioRef)
	vParameters = New Structure("Folio, Client, AccommodationType, CheckInDate, CheckOutDate, ParentDoc, Room, IdentityCardSystemParameters");
	vParameters.Folio = pFolioRef;
	If ValueIsFilled(pFolioRef) Then
		vParameters.Client = pFolioRef.Client;
		vParameters.ParentDoc = pFolioRef.ParentDoc;
		vParameters.CheckInDate = pFolioRef.DateTimeFrom;
		vParameters.CheckOutDate = pFolioRef.DateTimeTo;
		vParameters.Room = pFolioRef.Room;
		If TypeOf(vParameters.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParameters.ParentDoc) = Type("DocumentRef.Reservation") Then
			vParameters.AccommodationType = vParameters.ParentDoc.AccommodationType;
		EndIf;
	EndIf;
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vParameters.IdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;
		EndIf;
	EndIf;
	Return vParameters;
EndFunction // GetIdentityCardParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckIfIsExtraFolioAtServer(pFolioRef)
	vParentDoc = pFolioRef.ParentDoc;
	If ValueIsFilled(vParentDoc) And (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) Then
		If vParentDoc.ChargingRules.Find(pFolioRef, "ChargingFolio") = Undefined Then
			Return True;
		Else
			Return False;
		EndIf;
	Else
		Return True;
	EndIf;
EndFunction // CheckIfIsExtraFolioAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueIdentityCard(pFolioRef)
	If ValueIsFilled(pFolioRef) Then
		If Not tcOnServer.cmGetAttributeByRef(pFolioRef, "DeletionMark") Then
			vParameters = GetIdentityCardParameters(pFolioRef);
			If ValueIsFilled(vParameters.IdentityCardSystemParameters) Then
				vUseRoomForm = False;
				vArrIdentityCardSystemParameters = tcOnServer.cmGetAtributeAsArray(vParameters.IdentityCardSystemParameters);
				If vArrIdentityCardSystemParameters.IssueCardsForAllGuestsInTheRoom And ValueIsFilled(vParameters.Room) Then
					// Check if current folio is extra folio
					If Not CheckIfIsExtraFolioAtServer(pFolioRef) Then
						vUseRoomForm = True;
					EndIf;
				EndIf;
				If ValueIsFilled(vArrIdentityCardSystemParameters.ExternalInteraction) And 
						tcOnServer.cmGetAttributeByRef(vArrIdentityCardSystemParameters.ExternalInteraction, "IntegrationType") = PredefinedValue("Enum.Integrations.ISD") Then
					OpenForm("CommonForm.tcRoomIdentityCardsRegistrationISD", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);	
				ElsIf vUseRoomForm Then
					OpenForm("CommonForm.tcRoomIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
				Else
					OpenForm("CommonForm.tcClientIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
				EndIf;
			Else
				ShowMessageBox(, NStr("en='Client identity cards system is not configurated properly for the current workstation!';ru='Система карт идентификации клиентов на данном рабочем месте не настроена!';de='Das System für Kundenausweise ist auf diesem Arbeitsplatz nicht eingestellt!'"));
			EndIf;
		Else
			ShowMessageBox(, NStr("en='Folio should not be marked for deletion!';ru='Лицевой счет не должен быть помечен на удаление!';de='Das Personenkonto muss nicht zum Löschen markiert sein!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en='No folio is selected!';ru='Не выбран лицевой счет!';de='Kein Personenkonto ist gewählt!'"));
	EndIf;
EndProcedure // IssueIdentityCard

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoice(pInvoice)
	Notify("Subsystem.Accounts.Changed", pInvoice); 
	vLang = Undefined;
	vCustomer = tcOnServer.cmGetAttributeByRef(pInvoice, "AccountingCustomer");
	If ValueIsFilled(vCustomer) Then
		vLang = tcOnServer.cmGetAttributeByRef(vCustomer, "Language");
	EndIf;
	If TypeOf(pInvoice) = Type("DocumentRef.Settlement") Then
		vOpenInvoiceForm = True;
		vPrintForm = tcOnServer.GetInvoiceDefaultPrintForm(vLang);  
		If ValueIsFilled(vPrintForm) Then
			vAutomaticallyPrintOnFirstObjectWrite = tcOnServer.cmGetAttributeByRef(vPrintForm, "AutomaticallyPrintOnFirstObjectWrite");
			If vAutomaticallyPrintOnFirstObjectWrite Then
				vExtProcRef = tcOnServer.cmGetAttributeByRef(vPrintForm, "ExternalProcessing");
				If ValueIsFilled(vExtProcRef) Then 
					// Load external print form
					Try
						vURL = GetURL(vExtProcRef, "ExternalProcessingStorage"); 
						vName = ConnectExternalDataProcessor(vURL, "ExternalInvoicePrintingForm");
						vParams = New Structure("InputParameter, ObjectPrintingForm", pInvoice, vPrintForm);
					    vFrm = GetForm("ExternalDataProcessor." + vName + ".ObjectForm", vParams);
						vFrm.Open(); 
						vOpenInvoiceForm = False;
					Except
						tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
					EndTry;
				Else
					vPrintFormType = "Settlement";
					If vPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.SettlementPrintInvoiceRu") Or 
					   vPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.SettlementPrintInvoiceEn") Or
					   vPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.SettlementPrintInvoiceDe") Then
						vPrintFormType = "Invoice";
					EndIf;
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", pInvoice, vLang, vPrintForm, vPrintFormType), ThisObject, pInvoice);
					vOpenInvoiceForm = False;
				EndIf;
			EndIf;
		EndIf;
		If vOpenInvoiceForm Then
			OpenForm("Document.Settlement.ObjectForm", New Structure("Key", pInvoice), , pInvoice);
		EndIf;
	ElsIf TypeOf(pInvoice) = Type("DocumentRef.ProformaInvoice") Then
		vOpenProformaInvoiceForm = True;
		vPrintForm = tcOnServer.GetProformaInvoiceDefaultPrintForm(vLang); 
		If ValueIsFilled(vPrintForm) Then
			vAutomaticallyPrintOnFirstObjectWrite = tcOnServer.cmGetAttributeByRef(vPrintForm, "AutomaticallyPrintOnFirstObjectWrite");
			If vAutomaticallyPrintOnFirstObjectWrite Then
				vExtProcRef = tcOnServer.cmGetAttributeByRef(vPrintForm, "ExternalProcessing");
				If ValueIsFilled(vExtProcRef) Then
					// Load external print form
					Try
						vURL = GetURL(vExtProcRef, "ExternalProcessingStorage"); 
						vName = ConnectExternalDataProcessor(vURL, "ExternalProformainvoicePrintingForm");
						vParams = New Structure("InputParameter, ObjectPrintingForm", pInvoice, vPrintForm);
					    vFrm = GetForm("ExternalDataProcessor." + vName + ".ObjectForm", vParams);
						vFrm.Open(); 
						vOpenProformaInvoiceForm = False;
					Except
						tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
					EndTry;
				Else
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm", pInvoice, vLang, vPrintForm), ThisObject, pInvoice);
					vOpenProformaInvoiceForm = False;
				EndIf;
			EndIf;
		EndIf;
		If vOpenProformaInvoiceForm Then
			OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Key", pInvoice), , pInvoice);
		EndIf;
	EndIf;
EndProcedure // PrintInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoiceAfterInvoiceSelection(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vInvoice = pItem.Value;
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // PrintInvoiceAfterInvoiceSelection

// -----------------------------------------------------------------------------
&AtServer
Function FolioFillSettlement(pFolio, rMessage = "", rInvoice = Undefined, 
	pSelectedRows = Undefined, pListName = "", pInvoiceDate = '00010101')
	vResult = -1;
	rMessage = "";
	rInvoice = Undefined;
	If ValueIsFilled(pFolio) Then
		WriteLogEvent(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), EventLogLevel.Information, Metadata.Documents.Settlement, Documents.Settlement.EmptyRef(), NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
		vDoc = Documents.Settlement.CreateDocument();
		vDoc.Fill(pFolio);
		If ValueIsFilled(pInvoiceDate) Then
			vDoc.Date = EndOfDay(pInvoiceDate);
			vDoc.SetTime(AutoTimeMode.DontUse);
			vDoc.ChangeDate = CurrentSessionDate();
			vDoc.ChangeAuthor = SessionParameters.CurrentUser;
		EndIf;
		// Check if more then 1 transaction is selected
		vSelectedDocs = New ValueList();
		If pSelectedRows <> Undefined And pListName <> "" Then
			If pSelectedRows.Count() > 0 Then
				For Each vRowID In pSelectedRows Do
					vRowData = ThisObject[pListName].FindByID(vRowID);
					vRef = vRowData.Ref;
					If ValueIsFilled(vRef) And TypeOf(vRef) = Type("DocumentRef.Storno") Then
						vRef = vRef.ParentCharge;
					EndIf;
					vSelectedDocs.Add(vRef);
				EndDo;
				i = 0;
				While i < vDoc.Services.Count() Do
					vSrvRow = vDoc.Services.Get(i);
					If vSelectedDocs.FindByValue(vSrvRow.Charge) = Undefined Then
						vDoc.Services.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
				// Recalculate invoice totals
				vDoc.Sum = vDoc.Services.Total("Sum");
				vDoc.VATSum = vDoc.Services.Total("VATSum");
				vDoc.CommissionSum = vDoc.Services.Total("CommissionSum");
				vDoc.SumDue = vDoc.Sum - vDoc.PaymentDocuments.Total("Sum");
			EndIf;
		EndIf;
		If vDoc.Services.Count() > 0 Then
			If ValueIsFilled(pInvoiceDate) Then
				vDoc.Write(DocumentWriteMode.Write);
				If vDoc.Date <> EndOfDay(pInvoiceDate) Then
					vDoc.Date = EndOfDay(pInvoiceDate);
					vDoc.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			vDoc.Write(DocumentWriteMode.Posting);
			rInvoice = vDoc.Ref;
			vResult = 1;
		Else
			rMessage = NStr("en='Nothing to fill invoice for!';ru='Нет начислений для акта!';de='Nichts, um die Rechnung zu füllen!'");
			vResult = 0;
		EndIf;
	Else
		rMessage = NStr("en='No folio is selected!';ru='Не выбран лицевой счет!';de='Kein Personenkonto ist gewählt!'");
	EndIf;
	Return vResult;
EndFunction // FolioFillSettlement

// -----------------------------------------------------------------------------
&AtServer
Function GetListOfFolioInvoices(pFolio)
	vList = New ValueList();
	
	vFolioObj = pFolio.GetObject();
	
	vProformaInvoices = pFolio.GetObject().pmGetAllFolioProformaInvoices();
	For Each vProformaInvoicesRow In vProformaInvoices Do
		vInv = vProformaInvoicesRow.Document;
		vList.Add(vInv, TrimAll(vInv) + " - " + cmFormatSum(vInv.Sum, vInv.AccountingCurrency));
	EndDo;
	
	vInvoices = vFolioObj.pmGetAllFolioSettlements();
	For Each vInvoicesRow In vInvoices Do
		vInv = vInvoicesRow.Document;
		vList.Add(vInv, TrimAll(vInv) + " - " + cmFormatSum(vInv.Sum, vInv.AccountingCurrency));
	EndDo;
	
	Return vList;
EndFunction // GetListOfFolioInvoices

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHideCorrectionsOnChange(pItem)
	UpdatePanelsOnServer(False);
EndProcedure // SelHideCorrectionsOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure Split(pFolio, pFolioTransactionsName, pProcedureName)
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	vSelectedRow = GetSelectedRow(pFolioTransactionsName);
	If CheckUserPermissionsForTransactions(pFolio) And vSelectedRow <> Undefined Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", pProcedureName), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		
		vMessage = "";
		vSelDoc = Undefined;
		vRowData = ThisObject[pFolioTransactionsName].FindByID(vSelectedRow);
		If vRowData <> Undefined Then
			vSelDoc = vRowData.Ref;
			If TypeOf(vSelDoc) <> Type("DocumentRef.Charge") Then
				vSelDoc = Undefined;
			Else
				If ChargeIsCanceled(vSelDoc) Then
					vSelDoc = Undefined;
					vMessage = NStr("en='Selected charge was already canceled!'; ru='Выбранное начисление уже отменено!'; de='Die ausgewählte Posting wurde bereits storniert!'");
				EndIf;
			EndIf;
		EndIf;
		
		// Open new correction form
		If ValueIsFilled(vSelDoc) Then
			OpenForm("CommonForm.tcChargeSplitForm", New Structure("Charge, Folio", vSelDoc, pFolio), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
		Else
			If Not IsBlankString(vMessage) Then
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='No credit transaction selected!'; ru='Не выбрано начисление!'; de='Keine Kreditposting ausgewählt!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Split

// -----------------------------------------------------------------------------
&AtClient
Procedure BindToAccommodation(pFolio, pFolioTransactionsName, pProcedureName)
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	// Check if operation is possible
	If CheckUserPermissionsForTransactions(pFolio) Then
		// Fill list of selected charges
		vCharges = New Array;
		vSelRows = GetSelectedRows(pFolioTransactionsName);
		For Each vRowID In vSelRows Do
			vRowData = ThisObject[pFolioTransactionsName].FindByID(vRowID);
			If TypeOf(vRowData.Ref) <> Type("DocumentRef.Charge") Then
				Continue;
			EndIf;
			vCharges.Add(vRowData.Ref);
		EndDo;
		vRoomRevenueCharge = GetAllowedChargesForBinding(vCharges);
		If ValueIsFilled(vRoomRevenueCharge) And vCharges.Count() > 1 Then
			// Check user PIN if necessary
			If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
				OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", pProcedureName), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
			EmployeePINCodeChecked = False;
			
			// Do at server
			vErrorText = BindAtServer(vRoomRevenueCharge, vCharges);
			If Not IsBlankString(vErrorText) Then
				ShowMessageBox(, vErrorText, , NStr("en='Error!'; ru='Ошибка!'; de='Fehler!'"));
			Else
				Notify("Document.Charge.Write", vRoomRevenueCharge, ThisForm);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BindToAccommodation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ChargeIsCanceled(pDoc)
	Return cmIfChargeIsCanceled(pDoc);
EndFunction // ChargeIsCanceled

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPresentationFoliosList(pPage, pResetFolio = True)
	vItemGroupStandardFolio = Items.Find("FormGroupGroupStandardFolio"+pPage);
	If vItemGroupStandardFolio = Undefined Then
		vItemGroupStandardFolio = tcOnServer.cmCreateItem(ThisObject, Items["GroupFoliosButtons" + pPage], "GroupStandardFolio" + pPage, "FormGroup",
											New Structure("Type, Width, Group, ShowTitle", FormGroupType.UsualGroup, 0, ChildFormItemsGroup.Vertical, False));
	EndIf;
	
	vItemGroupMainFolio = vItemGroupStandardFolio;   
	vArrVisiblFolios = New Array;  
	vClient = MainGuest; 
	vFirst = True;    
	If pPage = "FolioDocumentsLeft" Then  
		vFolioPageType = FolioPageTypeLeft;
	Else            
		vFolioPageType = FolioPageTypeRight;
	EndIf;
	If vFolioPageType = 0 Then   
		If TypeOf(ObjectRef) = Type("DocumentRef.Folio") Then
			vFolioListRow = FolioList.FindByValue(ObjectRef);
			If Not vFolioListRow = Undefined Then  
				If pPage = "FolioDocumentsLeft" Then
					FolioRefLeft = ObjectRef;  
				Else            
					FolioRefRight = ObjectRef;
				EndIf;
				vArrVisiblFolios.Add(ObjectRef);
				CreateFolioLabel(ObjectRef, vItemGroupMainFolio, vFolioListRow, pPage);
			EndIf;
		Else	
			If ValueIsFilled(vClient) Then
				vFilterFolios = FoliosTypes.FindRows(New Structure("Type, Client", 0, vClient)); 
				For Each vRowFolioTypes In vFilterFolios Do 
					vFolioRef = vRowFolioTypes.Folio;     
					vFolioListRow = FolioList.FindByValue(vFolioRef);
					If Not vFolioListRow = Undefined Then  
						If pResetFolio And vFirst Then  
							vFirst = False;    
							If pPage = "FolioDocumentsLeft" Then
								FolioRefLeft = vFolioRef;  
							Else            
								FolioRefRight = vFolioRef;
							EndIf;
						EndIf;  
						vArrVisiblFolios.Add(vFolioRef);
						CreateFolioLabel(vFolioRef, vItemGroupMainFolio, vFolioListRow, pPage);
					EndIf;
				EndDo; 
			Else 	
				vFilterFolios = FoliosTypes.FindRows(New Structure("Type", 0)); 
				For Each vRowFolioTypes In vFilterFolios Do 
					vFolioRef = vRowFolioTypes.Folio;     
					vFolioListRow = FolioList.FindByValue(vFolioRef);
					If Not vFolioListRow = Undefined Then  
						If pResetFolio And vFirst Then  
							vFirst = False;    
							If pPage = "FolioDocumentsLeft" Then
								FolioRefLeft = vFolioRef;  
							Else            
								FolioRefRight = vFolioRef;
							EndIf;
						EndIf;  
						vArrVisiblFolios.Add(vFolioRef);
						CreateFolioLabel(vFolioRef, vItemGroupMainFolio, vFolioListRow, pPage);
					EndIf;
				EndDo; 
			EndIf; 
		EndIf;
	ElsIf vFolioPageType = 1 Then   
		If pPage = "FolioDocumentsLeft" Then  
			vSelGuest = SelectedAccompanyGuestsLeft;
		Else
			vSelGuest = SelectedAccompanyGuestsRight;
		EndIf;	
		vFilterFolios = FoliosTypes.FindRows(New Structure("Type", 0)); 
		For Each vRowFolioTypes In vFilterFolios Do  
			vFolioRef = vRowFolioTypes.Folio;
			vFolioListRow = FolioList.FindByValue(vFolioRef);
			If Not vFolioListRow = Undefined Then
				vSelGuestRows = vSelGuest.FindRows(New Structure("Client", vFolioRef.Client));
				If vSelGuestRows.Count() > 0 Then
					vSelGuestRow = vSelGuestRows.Get(0);
					If vSelGuestRow.Check Then 
						If pResetFolio And vFirst Then  
							vFirst = False;    
							If pPage = "FolioDocumentsLeft" Then
								FolioRefLeft = vFolioRef;  
							Else            
								FolioRefRight = vFolioRef;
							EndIf;
						EndIf;            
						vArrVisiblFolios.Add(vFolioRef);
						CreateFolioLabel(vFolioRef, vItemGroupMainFolio, vFolioListRow, pPage);
					EndIf;
				EndIf;
			EndIf;
		EndDo;  
	ElsIf vFolioPageType = 2 Then  
		vFilterFolios = FoliosTypes.FindRows(New Structure("Type", 3)); 
		For Each vRowFolioTypes In vFilterFolios Do  
			vFolioRef = vRowFolioTypes.Folio; 
			vFolioListRow = FolioList.FindByValue(vFolioRef);
			If Not vFolioListRow = Undefined Then     
				If pResetFolio And vFirst Then  
					vFirst = False;    
					If pPage = "FolioDocumentsLeft" Then
						FolioRefLeft = vFolioRef;  
					Else            
						FolioRefRight = vFolioRef;
					EndIf;
				EndIf;       
				vArrVisiblFolios.Add(vFolioRef);
				CreateFolioLabel(vFolioRef, vItemGroupMainFolio, vFolioListRow, pPage);
			EndIf;
		EndDo;  
	ElsIf vFolioPageType = 3 Then  
		vFilterFolios = FoliosTypes.FindRows(New Structure("Type", 1)); 
		For Each vRowFolioTypes In vFilterFolios Do  
			vFolioRef = vRowFolioTypes.Folio; 
			vFolioListRow = FolioList.FindByValue(vFolioRef);
			If Not vFolioListRow = Undefined Then    
				If pResetFolio And vFirst Then  
					vFirst = False;    
					If pPage = "FolioDocumentsLeft" Then
						FolioRefLeft = vFolioRef;  
					Else            
						FolioRefRight = vFolioRef;
					EndIf;
				EndIf;     
				vArrVisiblFolios.Add(vFolioRef);
				CreateFolioLabel(vFolioRef, vItemGroupMainFolio, vFolioListRow, pPage);
			EndIf;
		EndDo;  	
	EndIf;   
	// Hide folios that are not in list anymore
	Try
		For Each vFormItem In Items Do
			If Find(vFormItem.Name, "FormGroupGroupFolio" + pPage +"_")>0 And Right(vFormItem.Name, 7) <> "Tooltip" Then
				vID = Right(vFormItem.Name, 36);
				vID = StrReplace(vID, "_", "-");
				vFolioUUID = New UUID(vID);
				vFolio = Documents.Folio.GetRef(vFolioUUID);
				If vArrVisiblFolios.Find(vFolio) = Undefined Then
					vFormItem.Visible = False;  
				Else
					vFormItem.Visible = True;
				EndIf;
			EndIf;
		EndDo;
	Except
	EndTry;
EndProcedure // FillPresentationFoliosList

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateFolioLabel(pFolioRef, vItemGroupMainFolio, pRowFolio, pPage)
	
	vID = StrReplace(String(pFolioRef.UUID()), "-", "_");
	vBalance = pRowFolio.Presentation;
	vPreauthLimit = "";
	vSlashPos = StrFind(vBalance, "/");
	If vSlashPos > 0 Then
		vPreauthLimit = Mid(vBalance, vSlashPos + 1);
		vBalance = Left(vBalance, vSlashPos - 1);
	EndIf;
	vCMD = "SelectFolioLeft";
	If pPage = "FolioDocumentsRight" Then
		vCMD = "SelectFolioRight";	
	EndIf;	
	vClient = ?(ValueIsFilled(pFolioRef.Customer), pFolioRef.Customer, pFolioRef.Client);
	
	// Get formating string folio description
	vArrFD = New Array;
	vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", "№" + cmGetDocumentNumberPresentation(pFolioRef.Number), tcCommonFunctionOnClientServer.FontConstructor(, 8, True), , GetURL(pFolioRef)));
	If pFolioRef.IsClosed Then
		vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + NStr("en='Is closed'; ru='Закрыт'; de='Geschlossen'"), tcCommonFunctionOnClientServer.FontConstructor(, 9, True), WebColors.Red));
	EndIf;
	If Not IsBlankString(pFolioRef.Description) Then
		vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + TrimAll(pFolioRef.Description), tcCommonFunctionOnClientServer.FontConstructor(, 9, , )));
	EndIf;
	
	vFolioDescription = tcOnServer.cmGenerateFormattedString(vArrFD);
	
	// Group folio
	vItemGroupFolio = Items.Find("FormGroupGroupFolio" + pPage +"_" + vID);
	vGroupBackColor = tcCommonFunctionOnClientServer.ColorConstructor(245, 245, 245);
	If pPage = "FolioDocumentsLeft" And  pFolioRef = FolioRefLeft Then
		vGroupBackColor = GetSelectedFolioColor();
	EndIf;	
	If pPage = "FolioDocumentsRight" And pFolioRef = FolioRefRight And ValueIsFilled(FolioRefRight) And Split Then
		vGroupBackColor = GetSelectedFolioColor();
	EndIf;
	
	If vItemGroupFolio = Undefined Then
		vItemGroupFolio = tcOnServer.cmCreateItem(ThisObject, vItemGroupMainFolio,"GroupFolio" + pPage + "_" + vID, "FormGroup",
		New Structure("Type, Title, Width, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch",
		FormGroupType.UsualGroup, pFolioRef.Number, 20, vGroupBackColor , ChildFormItemsGroup.Vertical, False, False, False));
		vItemGroupFolio.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Else
		vItemGroupFolio.BackColor = vGroupBackColor; 
		vItemGroupFolio.Title = pFolioRef.Number;											
	EndIf;
	
	// Group customer
	vItemGroupCustomer = Items.Find("FormGroupGroupFolioCustomer" + pPage + "_" + vID);
	If vItemGroupCustomer = Undefined Then
		vItemGroupCustomer = tcOnServer.cmCreateItem(ThisObject, vItemGroupFolio,"GroupFolioCustomer" + pPage + "_" + vID, "FormGroup",
		New Structure("Type, Title, Width, Group, ShowTitle, HorizontalStretch, VerticalStretch",
		FormGroupType.UsualGroup, pFolioRef.Number, 19, ChildFormItemsGroup.AlwaysHorizontal, False, False, False));
	EndIf;
	
	// Payer
	vPic = PictureLib.Customer;
	vStr = FolioList.FindByValue(pFolioRef);
	If vStr <> Undefined Then
		vPic = vStr.Picture;
	EndIf;	
	// Client pict
	vItemPictClientDecoration = Items.Find("FormDecorationPictClient" + pPage + "_" + vID);
	If vItemPictClientDecoration = Undefined Then
		tcOnServer.cmCreateItem(ThisObject , vItemGroupCustomer, "PictClient" + pPage + "_" +  vID, "FormDecoration", 
								New Structure("Type, Title, Picture, Width, Height, HorizontalAlignInGroup", 
								FormDecorationType.Picture, "PictClient" + pPage + "_" +  vID, vPic, 2, 1, ItemHorizontalLocation.Left));
	Else						
		vItemPictClientDecoration.Picture = vPic;
	EndIf;	
	vClientPres = vClient;
	If TypeOf(vClient) = Type("CatalogRef.Clients") And ValueIsFilled(vClient) Then
		vClientPres = TrimAll(vClient.FullName);
	EndIf;	
	vItemClientDecoration = Items.Find("FormDecorationClient" + pPage + "_" + vID);
	If vItemClientDecoration = Undefined Then
		tcOnServer.cmCreateItem(ThisObject , vItemGroupCustomer, "Client" + pPage + "_" +  vID, "FormDecoration", 
								New Structure("Type, Title, Width, Height, HorizontalAlign, Font, HorizontalStretch, SetActionClick", 
								FormDecorationType.Label, vClientPres, 14, 1, ItemHorizontalLocation.Left, tcCommonFunctionOnClientServer.FontConstructor(, 8, True), True, vCMD));
	Else						
		vItemClientDecoration.Title = vClientPres;
	EndIf;	
	
	// Detailed client info                                                               
	vItemClientDecoration = Items.Find("FormDecorationClientInfo" + pPage +"_" + vID);
	If ValueIsFilled(pFolioRef.Customer) Then 
		If vItemClientDecoration = Undefined Then
			tcOnServer.cmCreateItem(ThisObject , vItemGroupFolio, "ClientInfo" + pPage +"_" +  vID, "FormDecoration", 
									New Structure("Type, Title, Width, Height, HorizontalAlign, Font, HorizontalStretch, SetActionClick", 
									FormDecorationType.Label, pFolioRef.Client, 14, 1, ItemHorizontalLocation.Left, tcCommonFunctionOnClientServer.FontConstructor(, 8), True, vCMD));
		Else						
			vItemClientDecoration.Title = pFolioRef.Client;
			vItemClientDecoration.Visible = True;
		EndIf;
	Else
		If Not vItemClientDecoration = Undefined Then
			vItemClientDecoration.Visible = False;
		EndIf;	
	EndIf;
	
	// Balance
	vItemBalanceDecoration = Items.Find("FormDecorationBalance" + pPage +"_" + vID);
	vBalanceColor = ?(pRowFolio.Check, tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0), tcCommonFunctionOnClientServer.ColorConstructor(51, 51, 51));
	If vItemBalanceDecoration = Undefined Then
		tcOnServer.cmCreateItem(ThisObject , vItemGroupFolio, "Balance" + pPage +"_" +  vID, "FormDecoration", 
								New Structure("Type, Title, TextColor, Height, HorizontalAlign, Font, HorizontalStretch, Hyperlink, SetActionClick", 
								FormDecorationType.Label, vBalance, vBalanceColor, 1, ItemHorizontalLocation.Center, tcCommonFunctionOnClientServer.FontConstructor(, 12, True), True, True, vCMD));
	Else
		vItemBalanceDecoration.Title = vBalance;
		vItemBalanceDecoration.TextColor = vBalanceColor;
	EndIf;	
	
	// Preauthorisation limit
	If Not IsBlankString(vPreauthLimit) Then
		vItemPreauthDecoration = Items.Find("FormDecorationPreauthLimit" + pPage +"_" + vID);
		If vItemPreauthDecoration = Undefined Then
			vItemPreauthDecoration = tcOnServer.cmCreateItem(ThisObject, vItemGroupFolio, "PreauthLimit" + pPage +"_" + vID, "FormDecoration",
															New Structure("Type, Title, TextColor, Height, HorizontalAlign, Font, HorizontalStretch, Hyperlink, SetActionClick",
															FormDecorationType.Label, vPreauthLimit, vBalanceColor, 1, ItemHorizontalLocation.Center, tcCommonFunctionOnClientServer.FontConstructor(, 10, True), True, True, vCMD));
		EndIf;
	Else
		vItemPreauthDecoration = Items.Find("FormDecorationPreauthLimit" + pPage +"_" + vID);
		If vItemPreauthDecoration <> Undefined Then
			vItemPreauthDecoration.Title = "";
		EndIf;
	EndIf;
	
	// Folio description
	vItemFolioDescription = Items.Find("FormDecorationFolioDescription" + pPage +"_" + vID);
	If vItemFolioDescription = Undefined Then
		tcOnServer.cmCreateItem(ThisObject , vItemGroupFolio, "FolioDescription" + pPage +"_" +  vID, "FormDecoration", 
								New Structure("Type, Title, Height, HorizontalAlign,  HorizontalStretch, SetActionClick", 
								FormDecorationType.Label, vFolioDescription, 1, ItemHorizontalLocation.Left, True, vCMD));
	Else
		vItemFolioDescription.Title = vFolioDescription;
	EndIf;

EndProcedure // FillPresentationFoliosList

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioRefByUUID(pUUID)
	vDoc = Documents.Folio.GetRef(New UUID(pUUID));
	If vDoc.IsEmpty() Or vDoc.GetObject() = Undefined Then
		 vDoc = Undefined;
	EndIf;	
	Return vDoc;
EndFunction //  GetFolioRefByUUID() 

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetSelectedFolioColor()
	Return tcCommonFunctionOnClientServer.ColorConstructor(228, 236, 242);
EndFunction // GetLeftSelectedFolioColor

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClosedFolioBackColor()
	Return tcCommonFunctionOnClientServer.ColorConstructor(242, 242, 242);
EndFunction // GetClosedFolioBackColor

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateInvoiceAtClient(pDate, pParams) Export
	If pDate = Undefined Then
		Return;
	EndIf;
	vInvoice = Undefined;
	vMessage = "";
	// Create invoice
	If FolioFillSettlement(pParams.Folio, vMessage, vInvoice, pParams.SelectedRows, pParams.TransactionListName, pDate) = 1 Then
		UpdatePanelsOnServer(False, False, False);
		If pParams.TransactionListName = "FolioDocumentsLeft" Then
			InvoiceLeft(Commands.PrintInvoiceLeft, vInvoice);
		Else
			InvoiceRight(Commands.PrintInvoiceRight, vInvoice);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
EndProcedure // CreateInvoiceAtClient

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetInvoiceDefaultLanguage(pInvoice)
	If ValueIsFilled(pInvoice) Then
		If ValueIsFilled(pInvoice.AccountingCustomer) And ValueIsFilled(pInvoice.AccountingCustomer.Language) Then
			Return pInvoice.AccountingCustomer.Language;
		ElsIf ValueIsFilled(pInvoice.Hotel) Then
			Return pInvoice.Hotel.Language;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetInvoiceDefaultLanguage

// -----------------------------------------------------------------------------
&AtServer
Function GetServiceList(pFrom)
	vServiceList = New ValueList();
	If pFrom = "Left" Then
		vTree = "FolioDocumentsLeft";
	ElsIf pFrom = "Right" Then 
		vTree = "FolioDocumentsRight";
	EndIf;
	For Each vRow In ThisObject[vTree].GetItems() Do
		If Not vRow.IsPayment Then
			If vRow.GetItems().Count() > 0 Then
				For Each vChildRow In vRow.GetItems() Do
					If Not vChildRow.IsPayment Then
						If vServiceList.FindByValue(vChildRow.Service) = Undefined Then
							vServiceList.Add(vChildRow.Service);
						EndIf;
					EndIf;
				EndDo;
			Else
				If vServiceList.FindByValue(vRow.Service) = Undefined Then
					vServiceList.Add(vRow.Service);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vServiceList;
EndFunction // GetServiceList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCheckService(pList, pExtraParams) Export 
	If pList <> Undefined Then
		vService = New Array();
		For Each vItem In pList Do
			If vItem.Check Then 
				vService.Add(vItem.Value);
			EndIf;
		EndDo;
		vTree = ""; 
		If pExtraParams = "Left" Then
			Items.FolioDocumentsLeftSelectTransactionsLeft.Check = True;
			Items.FolioDocumentsLeftIsChecked.Visible = True;
			vTree = "FolioDocumentsLeft";
		ElsIf pExtraParams = "Right" Then
			Items.FolioDocumentsRightSelectTransactionsRight.Check = True;
			Items.FolioDocumentsRightIsChecked.Visible = True;
			vTree = "FolioDocumentsRight";
		EndIf;
		For Each vRow In ThisObject[vTree].GetItems() Do
			If vRow.GetItems().Count() > 0 Then
				For Each vChildRow In vRow.GetItems() Do
					If vService.Find(vChildRow.Service) <> Undefined Then 
						vRow.IsChecked = True;
					EndIf;
				EndDo;
			Else
				If vService.Find(vRow.Service) <> Undefined Then
					vRow.IsChecked = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // AfterCheckService

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioDocumentsIsCheckedOnChange(pItem)
	If pItem.Name = "FolioDocumentsLeftIsChecked" Then
		vFolioDocumentsList = Items.FolioDocumentsLeft;
	Else
		vFolioDocumentsList = Items.FolioDocumentsRight;
	EndIf;
	vCurRowID = vFolioDocumentsList.CurrentRow;
	vRowData = vFolioDocumentsList.CurrentData;
	If vRowData <> Undefined Then
		If vRowData.IsPayment Then
			vRowData.IsChecked = False;
		Else
			If vRowData.IsChecked Then
				vFolioDocumentsList.SelectedRows.Add(vFolioDocumentsList.CurrentRow);
			Else
				i = 0;
				While i < vFolioDocumentsList.SelectedRows.Count() Do
					vSelRowID = vFolioDocumentsList.SelectedRows.Get(i);
					If vSelRowID = vCurRowID Then
						vFolioDocumentsList.SelectedRows.Delete(i);
						Break;
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	ControlVisibility(vFolioDocumentsList.Name);
EndProcedure // FolioDocumentsIsCheckedOnChange

// -----------------------------------------------------------------------------
Function GetNumberOfSelectedFirstLevelRows(pItemName)
	vCount = 0;
	vTable = Undefined;
	vSelectionSwitch = Undefined;
	If pItemName = "FolioDocumentsLeft" Then
		vTable = ThisObject["FolioDocumentsLeft"];
		vSelectionSwitch = Items.FolioDocumentsLeftSelectTransactionsLeft;
	ElsIf pItemName = "FolioDocumentsRight" Then
		vTable = ThisObject["FolioDocumentsRight"];
		vSelectionSwitch = Items.FolioDocumentsRightSelectTransactionsRight;
	EndIf;
	vSelectedRows = New Array();
	If vTable <> Undefined Then
		If vSelectionSwitch.Check Then
			For Each vRowData In vTable.GetItems() Do
				If vRowData.IsChecked Then
					vCount = vCount + 1;
				EndIf;
			EndDo;
		EndIf;
		If vCount = 0 Then
			vSelectedRows = Items[pItemName].SelectedRows;
			i = 0;
			While i < vSelectedRows.Count() Do
				vSelectedRowId = vSelectedRows.Get(i);
				vSelectedRowData = ThisObject[pItemName].FindByID(vSelectedRowId);
				If vSelectedRowData <> Undefined And vSelectedRowData.GetParent() = Undefined And Not vSelectedRowData.IsPayment Then
					If vSelectedRowData.GetItems().Count() > 0 Then
						vCount = vCount + 1;
					EndIf;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
	EndIf;
	Return vCount;
EndFunction // GetNumberOfSelectedFirstLevelRows

// -----------------------------------------------------------------------------
Function GetSelectedRows(pItemName, pIsCorrection = False, pMarkedOnly = False)
	vTable = Undefined;
	vSelectionSwitch = Undefined;
	If pItemName = "FolioDocumentsLeft" Then
		vTable = ThisObject["FolioDocumentsLeft"];
		vSelectionSwitch = Items.FolioDocumentsLeftSelectTransactionsLeft;
	ElsIf pItemName = "FolioDocumentsRight" Then
		vTable = ThisObject["FolioDocumentsRight"];
		vSelectionSwitch = Items.FolioDocumentsRightSelectTransactionsRight;
	EndIf;
	vSelectedRows = New Array();
	If vTable <> Undefined Then
		If vSelectionSwitch.Check Then
			For Each vRowData In vTable.GetItems() Do
				If vRowData.IsChecked Then
					If vRowData.GetItems().Count() > 0 Then
						For Each vRowDataItem In vRowData.GetItems() Do
							vSelectedRows.Add(vRowDataItem.GetID());
						EndDo;
					Else
						vSelectedRows.Add(vRowData.GetID());
					EndIf;
				Else
					If vRowData.GetItems().Count() > 0 Then
						For Each vRowDataItem In vRowData.GetItems() Do
							If vRowDataItem.IsChecked Then
								vSelectedRows.Add(vRowDataItem.GetID());
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If Not pMarkedOnly Then
			If vSelectedRows.Count() = 0 Then
				vSelectedRows = New Array();
				For Each vSelRow In Items[pItemName].SelectedRows Do
					vSelectedRows.Add(vSelRow);
				EndDo;
			EndIf;
		EndIf;
		i = 0;
		While i < vSelectedRows.Count() Do
			vSelectedRowId = vSelectedRows.Get(i);
			vSelectedRowData = ThisObject[pItemName].FindByID(vSelectedRowId);
			If vSelectedRowData <> Undefined And vSelectedRowData.GetItems().Count() > 0 And Not ValueIsFilled(vSelectedRowData.Ref) Then
				j = i;
				vFirstWasAdded = False;
				For Each vChildRowData In vSelectedRowData.GetItems() Do
					vSelectedRows.Insert(i + 1, vChildRowData.GetID());
					i = i + 1;
					If Not vFirstWasAdded Then
						vFirstWasAdded = True;
						If pIsCorrection Then
							Break;
						EndIf;
					EndIf;
				EndDo;
				vSelectedRows.Delete(j);
				i = i - 1;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	Return vSelectedRows;
EndFunction // GetSelectedRows

// -----------------------------------------------------------------------------
&AtClient
Function GetSelectedRow(pItemName)
	vTable = Undefined;
	If pItemName = "FolioDocumentsLeft" Then
		vTable = ThisObject["FolioDocumentsLeft"];
	ElsIf pItemName = "FolioDocumentsRight" Then
		vTable = ThisObject["FolioDocumentsRight"];
	EndIf;
	vSelectedRowId = Undefined;
	If vTable <> Undefined Then
		vSelectedRowId = Items[pItemName].CurrentRow;
		vSelectedRowData = ThisObject[pItemName].FindByID(vSelectedRowId);
		If vSelectedRowData.GetItems().Count() > 0 Then
			vSelectedRowId = vSelectedRowData.GetItems().Get(0).GetID();
		EndIf;
	EndIf;
	Return vSelectedRowId;
EndFunction // GetSelectedRow

// -----------------------------------------------------------------------------
&AtServer
Function GetAllowedChargeForReversal(pPage)
	vDocs = New Array;
	vRows = GetSelectedRows(pPage);
	For Each vStr In vRows Do
		vStrData = ThisObject[pPage].FindByID(vStr);
		If Not TypeOf(vStrData.Ref)=Type("DocumentRef.Charge")  Then
			Continue;
		EndIf;
		vCharge = vStrData.Ref;
		
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Charge.Ref AS Ref
		|FROM
		|	Document.Charge AS Charge
		|		LEFT JOIN Document.Storno AS Storno
		|		ON (Charge.Ref = Storno.ParentCharge
		|				AND Storno.Posted
		|				AND NOT Storno.DeletionMark)
		|WHERE
		|	Charge.Posted
		|	AND Charge.DeletionMark = FALSE
		|	AND Charge.CorrectedCharge = &qCharge
		|	AND Charge.Ref <> &qCharge
		|	AND Storno.Ref IS NULL";
		
		vQuery.SetParameter("qCharge", vCharge);
		
		vResult = vQuery.Execute();
		
		If vResult.IsEmpty() Then
			vDocs.Add(vCharge);
		Else
			tcCommonFunctionOnClientServer.UserMessage(Nstr(StrTemplate("en = 'Corrections were made for the accrual of %1, service ""%2"" cancellation is not possible.'; 
									 |de = 'Korrekturen wurden für die Rückstellung von %1 vorgenommen, eine Stornierung von Service ""%2"" ist nicht möglich.'; 
									 |ru = 'Для начисления %1, услуги ""%2"" уже сделаны корректировки, отмена невозможна.'", vCharge.Number, vCharge.Service)));
		EndIf;
	EndDo;
	
	Return vDocs;
EndFunction //  GetAllowedChargeForReversal

// -----------------------------------------------------------------------------
&AtClient
Procedure Correction(pFolio, pFolioTransactionsName, pProcedureName)
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	vSelectedRowsForAmount = GetSelectedRows(pFolioTransactionsName);
	vSelectedRows = GetSelectedRows(pFolioTransactionsName, True);
	If CheckUserPermissionsForTransactions(pFolio) And vSelectedRows.Count() > 0 Then
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", pProcedureName), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		
		vSelDoc = Undefined;
		vDocsAmount = 0;
		vPaymentCorrectionMode = False;
		vMultiplePaymentsWereSelected = False;
		If vSelectedRowsForAmount.Count() > 0 Then
			For Each vRowID In vSelectedRowsForAmount Do
				vRowData = ThisObject[pFolioTransactionsName].FindByID(vRowID);
				If vRowData <> Undefined Then
					vSelDoc = vRowData.Ref;
					If TypeOf(vSelDoc) = Type("DocumentRef.Payment") Then
						If Not vPaymentCorrectionMode Then
							vPaymentCorrectionMode = True;
						Else
							vMultiplePaymentsWereSelected = True;
						EndIf;
					ElsIf TypeOf(vSelDoc) = Type("DocumentRef.Charge") Then
						vPaymentCorrectionMode = False;
						If vRowData.Sum > 0 Then
							vDocsAmount = vDocsAmount + vRowData.Sum;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If vPaymentCorrectionMode And ValueIsFilled(vSelDoc) Then
			If vMultiplePaymentsWereSelected Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Please select one payment!'; ru='Пожалуйста, выберите один платеж!'; de='Bitte wählen Sie eine Zahlung aus!'"));
			Else
				OpenForm("CommonForm.tcPaymentCorrectionForm", New Structure("Payment", vSelDoc), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else
			vDocsList = New ValueList();
			If vSelectedRows.Count() > 0 Then
				For Each vRowID In vSelectedRows Do
					vRowData = ThisObject[pFolioTransactionsName].FindByID(vRowID);
					If vRowData <> Undefined Then
						vSelDoc = vRowData.Ref;
						If TypeOf(vSelDoc) = Type("DocumentRef.Charge") Then
							If vRowData.Sum > 0 Then
								vDocsList.Add(vSelDoc);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
			// Open new correction form
			If vDocsList.Count() > 0 Then
				OpenForm("CommonForm.tcManualCorrectionForm", New Structure("Charges, Folio, Amount", vDocsList, pFolio, vDocsAmount), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='No credit transactions selected!'; ru='Не выбраны начисления!'; de='Keine Kreditgeschäfte ausgewählt!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Correction

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetTransactionsQueryText()
	Return cmGetTransactionsQueryText();
EndFunction // GetTransactionsQueryText

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure GetSelectedTransactions(Val pPage, Val pRows, pTransactions)
	For Each vStr In pRows Do
		vStrData = ThisObject[pPage].FindByID(vStr);
		If ValueIsFilled(vStrData.Ref) Then
			pTransactions.Add(vStrData.Ref);
		EndIf;
	EndDo;
EndProcedure //  GetSelectedTransactions

// ------------------------------------------------------------------------------------------------
&AtServer
Function CheckIfProformaInvoicesExist(pFolio)
	vQuery = New Query();
	vQuery.Text =
	"SELECT TOP 1
	|	ProformaInvoice.Ref AS Invoice,
	|	ProformaInvoice.Date AS Date,
	|	ProformaInvoice.Sum AS Sum
	|FROM
	|	Document.ProformaInvoice AS ProformaInvoice
	|WHERE
	|	ProformaInvoice.ParentDoc = &qParentDoc
	|	AND ProformaInvoice.Posted";
	vQuery.SetParameter("qParentDoc", pFolio);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckIfProformaInvoicesExist

// ------------------------------------------------------------------------------------------------
&AtServer
Function CreateNewOrEditExistingProformaInvoice(pTree, pIsCheckedColumn, pFolio)
	vStruct = New Structure();
	vTree = FormAttributeToValue(pTree);
	vStruct.Insert("Type", pFolio);
	vStruct.Insert("Tree", vTree);
	vStruct.Insert("AllRows", pIsCheckedColumn);
	If Not ChosenInvoice.IsEmpty() Then
		vProformaInvoice = ChosenInvoice.GetObject();
	Else
		vProformaInvoice = Documents.ProformaInvoice.CreateDocument();
	EndIf;
	AllRowsAreNotChecked(vTree);
	If Not pIsCheckedColumn Or Not Counter Then 
		vProformaInvoice.Fill(pFolio);
	Else
		vProformaInvoice.Fill(vStruct);
		Counter = False;
	EndIf;
	
	vProformaInvoice.Write(DocumentWriteMode.Posting);
	Return vProformaInvoice.Ref;
EndFunction // CreateNewOrEditExistingProformaInvoice

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetNumberAndSumOfServices(pTree, pIsCheckedColumn, pFolio)
	vNumber = 0;
	vSum = 0;
	vCurrency = pFolio.FolioCurrency;
	vTree = FormAttributeToValue(pTree);
	If Not pIsCheckedColumn Then
		For Each vTreeRow In vTree.Rows Do
			vNumber = vNumber + 1;
			vSum = vSum + vTreeRow.Sum;
		EndDo;
	Else
		TraverseTreeRecursivelyTreeRows(vTree, vNumber, vSum);
	EndIf;
	Return New Structure("Number, Sum, Currency", vNumber, vSum, vCurrency);
EndFunction // GetNumberAndSumOfServices

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure TraverseTreeRecursivelyTreeRows(pTree, rNumber, rSum)
	For Each vTreeRow In pTree.Rows Do
		If vTreeRow.IsChecked Then
			rNumber = rNumber + 1; 
			rSum = rSum + vTreeRow.Sum;
		EndIf;
		If vTreeRow.Rows.Count() > 0 And Not vTreeRow.IsChecked Then
			TraverseTreeRecursivelyTreeRows(vTreeRow, rNumber, rSum);
		EndIf;
	EndDo;
EndProcedure // TraverseTreeRecursivelyTreeRows

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure Attacheble_AfterSelectedPreauthorisation(pPreauthorisation, pAdditionalParams) Export 
	If ValueIsFilled(pPreauthorisation) Then  
		// Calculate last existing preauthorisation
		OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", pPreauthorisation, pPreauthorisation), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	Else          
		// Nothing
	EndIf;	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure Attacheble_AfterQueryBoxPreauthorisation(pResult, pAdditionalParams) Export 
	If pResult = DialogReturnCode.Yes Then  
		// Calculate last existing preauthorisation
		vFilter = New Structure;
		vFilter.Insert("Folio", pAdditionalParams.Folio);
		vFilter.Insert("Status", PredefinedValue("Enum.PreauthorisationStatuses.Authorised"));  
		vParatersForm = New Structure("Filter", vFilter); 
		vND = New NotifyDescription("Attacheble_AfterSelectedPreauthorisation", ThisObject, New Structure("Folio", vFilter.Folio));
		OpenForm("Document.Preauthorisation.Form.tcChoiceForm", vParatersForm, ThisObject, UniqueKey, , , vND, FormWindowOpeningMode.LockWholeInterface);
	Else
		// Create new payment
		OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, Document", pAdditionalParams.Folio, pAdditionalParams.Folio), ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;	
EndProcedure    

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckPreauthorisation(pFolio)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Preauthorisation.Ref AS Ref
	|FROM
	|	Document.Preauthorisation AS Preauthorisation
	|WHERE
	|	Preauthorisation.DeletionMark = FALSE
	|	AND Preauthorisation.Posted = TRUE
	|	AND Preauthorisation.Folio = &qFolio
	|	AND Preauthorisation.Status = VALUE(Enum.PreauthorisationStatuses.Authorised)";
	vQuery.SetParameter("qFolio", pFolio);
	
	vQueryResult = vQuery.Execute();
	If vQueryResult.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction

// -----------------------------------------------------------------------------  
&AtServer
Procedure AllRowsAreNotChecked(pTree)
	For Each TreeRow In pTree.Rows Do
		If TreeRow.IsChecked Then
			Counter = True;
		EndIf;
		If TreeRow.Rows.Count() > 0 Then
			AllRowsAreNotChecked(TreeRow);
		EndIf;
	EndDo; 
EndProcedure // AllRowsAreNotChecked

// -----------------------------------------------------------------------------  
&AtServerNoContext
Function ChargeIsMerged(pChargeRef)
	vResult = False;
	If ValueIsFilled(pChargeRef) And pChargeRef.IsMergedToRoomRevenue And pChargeRef.IsInPrice And pChargeRef.IsRoomRevenue And Not pChargeRef.IsSplit And Not pChargeRef.RoomRevenueAmountsOnly Then
		vMergedTransactions = cmGetRoomRateTransactions(pChargeRef);
		If vMergedTransactions.Count() > 1 Then
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // ChargeIsMerged

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllowedChargesForBinding(pChargesArray)
	vRoomRevenueCharge = Undefined;
	vAccountingDate = '00010101';
	// Remove charges with storno and corrections
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
			Continue;
		Else
			// Only one room revenue charge could be selected
			If vCharge.IsInPrice And vCharge.IsRoomRevenue And Not vCharge.IsSplit And Not vCharge.RoomRevenueAmountsOnly Then
				If Not ValueIsFilled(vRoomRevenueCharge) Then
					vCurAccountingDate = BegOfDay(vCharge.Date);
					If Not ValueIsFilled(vAccountingDate) Then
						vAccountingDate = vCurAccountingDate;
					Else
						If vCurAccountingDate <> vAccountingDate Then
							tcCommonFunctionOnClientServer.UserMessage(Nstr(StrTemplate("en = 'All selected charges should be in the one accounting date! Charge %1 for service ""%2"" is removed from the list selected.'; 
													                                    |de = 'Alle ausgewählten Gebühren sollten an einem Abrechnungsdatum liegen! Die Gebühr %1 für den Dienst ""%2"" wird aus der ausgewählten Liste entfernt.'; 
													                                    |ru = 'Все выбранные начисления должны быть в одной учетной дате! Начисление %1 по услуге ""%2"" удалено из списка выбранных начислений.'", 
							                                                            vCharge.Number, vCharge.Service)));
							pChargesArray.Delete(i);
							Continue;
						EndIf;
					EndIf;
					vRoomRevenueCharge = vCharge;
				Else
					tcCommonFunctionOnClientServer.UserMessage(Nstr(StrTemplate("en = 'Only one room revenue charge could be selected for binding! Charge %1 for service ""%2"" is removed from the list selected.'; 
											                                    |de = 'Es konnte nur eine Zimmerumsatzgebühr zur Bindung ausgewählt werden! Gebühr %1 für Dienst ""%2"" wurde aus der ausgewählten Liste entfernt.'; 
											                                    |ru = 'Выбранные начисления связываются с одним начислением проживания. Выбрали более одного! Начисление %1 по услуге ""%2"" удалено из списка выбранных начислений.'", 
					                                                            vCharge.Number, vCharge.Service)));
					pChargesArray.Delete(i);
					Continue;
				EndIf;
			Else
				vCurAccountingDate = BegOfDay(vCharge.Date);
				If ValueIsFilled(vCharge.Service) And ValueIsFilled(vCharge.Service.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vCharge.Service.QuantityCalculationRule, vCharge.IsManual, vCharge.ParentDoc);
					If vAccountingDateMove < 0 Then
						vCurAccountingDate = vCurAccountingDate - 24*3600;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vAccountingDate) Then
					vAccountingDate = vCurAccountingDate;
				EndIf;
				
				// Remove charges with accounting date different from the room revenue service accounting date
				If vCurAccountingDate <> vAccountingDate Then
					tcCommonFunctionOnClientServer.UserMessage(Nstr(StrTemplate("en = 'All selected charges should be in the one accounting date! Charge %1 for service ""%2"" is removed from the list selected.'; 
											                                    |de = 'Alle ausgewählten Gebühren sollten an einem Abrechnungsdatum liegen! Die Gebühr %1 für den Dienst ""%2"" wird aus der ausgewählten Liste entfernt.'; 
											                                    |ru = 'Все выбранные начисления должны быть в одной учетной дате! Начисление %1 по услуге ""%2"" удалено из списка выбранных начислений.'", 
					                                                            vCharge.Number, vCharge.Service)));
					pChargesArray.Delete(i);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	// Check that room revenue charge is found
	If Not ValueIsFilled(vRoomRevenueCharge) Then
		tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Room revenue charge to bind other services to was not selected!'; 
								                        |de = 'Die Gebühr für die Zimmereinnahmen, an die andere Dienste gebunden sind, wurde nicht ausgewählt!'; 
								                        |ru = 'Не выбрано начисление проживания, в которое подвязываются остальные выбранные услуги!'"));
	Else
		If vRoomRevenueCharge.IsMergedToRoomRevenue Then
			tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Room revenue charge selected has some extra services binded to it already! Operation is canceled.'; 
									                        |de = 'Zusätzliche Leistungen sind bereits an die gewählte Übernachtungsgebühr gebunden! Der Vorgang wurde abgebrochen.'; 
									                        |ru = 'К выбранному начислению проживания уже подвязаны дополнительные услуги! Операция отменена.'"));
			vRoomRevenueCharge = Undefined;
		EndIf;
	EndIf;
	Return vRoomRevenueCharge;
EndFunction // GetAllowedChargesForBinding

// -----------------------------------------------------------------------------
&AtServerNoContext
Function BindAtServer(pRoomRevenueCharge, pChargesArray)
	vErrorText = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		vExtraSum = 0;
		vExtraDiscountSum = 0;
		vExtraCommissionSum = 0;
		// Process extra service charges
		For Each vCharge In pChargesArray Do
			If vCharge <> pRoomRevenueCharge Then
				vChargeObj = vCharge.GetObject();
				vChargeObj.IsMergedToRoomRevenue = True;
				vChargeObj.RoomRevenueCharge = pRoomRevenueCharge;
				vChargeObj.RateSum = 0;
				vChargeObj.RateDiscountSum = 0;
				vChargeObj.RateCommissionSum = 0;
				vChargeObj.Write(DocumentWriteMode.Posting);

				vExtraSum = vExtraSum + vChargeObj.Sum;
				vExtraDiscountSum = vExtraDiscountSum + vChargeObj.DiscountSum;
				vExtraCommissionSum = vExtraCommissionSum + vChargeObj.CommissionSum;
			EndIf;
		EndDo;
		// Process room revenue charge
		vRoomRevenueChargeObj = pRoomRevenueCharge.GetObject();
		vRoomRevenueChargeObj.IsMergedToRoomRevenue = True;
		vRoomRevenueChargeObj.RoomRevenueCharge = Undefined;
		vRoomRevenueChargeObj.RateSum = vRoomRevenueChargeObj.Sum + vExtraSum;
		vRoomRevenueChargeObj.RateDiscountSum = vRoomRevenueChargeObj.DiscountSum + vExtraDiscountSum;
		vRoomRevenueChargeObj.RateCommissionSum = vRoomRevenueChargeObj.CommissionSum + vExtraCommissionSum;
		vRoomRevenueChargeObj.Write(DocumentWriteMode.Posting);
		// Commit transaction
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		vErrorText = cmGetRootErrorDescription(vErrorInfo);
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorText;
EndFunction // BindAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomRateTransactions(pChargeRef)
	vMergedTransactions = cmGetRoomRateTransactions(pChargeRef);
	Return vMergedTransactions.UnloadColumn("Ref");
EndFunction // GetRoomRateTransactions

#EndRegion
