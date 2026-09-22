
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	WasNew = False;
	If Not ValueIsFilled(Object.Ref) Then
		WasNew = True;
	EndIf;
	
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If Parameters.Property("Hotel") And Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Object.Hotel) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Hotel is not choosen!'; ru='Не выбран отель!'; de='Hotel ist nicht gewählt!'"));
	EndIf;
	
	FillOrderTypesList();
	
	If ValueIsFilled(Object.TransferType) Then
		FillTransferRoute();
	EndIf;
	
	RouteTypeView();
	
	// Check if order charge was canceled
	If ValueIsFilled(Object.Charge) Then
		If CheckIfOrderChargeWasCanceled() Then
			ReadOnly = True;
			Items.GroupStatus.ReadOnly = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Order charge is canceled! Order is read only'; 
															|de = 'Bestellgebühr wird storniert! Die Bearbeitung einer solchen Bestellung ist verboten'; 
															|ru = 'Начисление этого заказа отменено! Редактирование такого заказа запрещено'"));
		EndIf;
	EndIf;
	
	Items.ManualPriceChangeReason.ChoiceList.LoadValues(GetArrayOfAllPriceChangeReasons());
	
	FillDepartmentsList();
	
	FillRoomAndPhone();
	
	EditForm();
	
	CheckExternalSystem();
	ChangeEnabledGetUnallocatedMedicalServices();
	If WasNew And ValueIsFilled(Object.Client) And ValueIsFilled(ExternalSystem) Then
		GetUnallocatedMedicalServicesAtServer();
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Object.Hotel, "BackgroundColorImportant");
	
	// Printing button appearance
	If Not WasNew Then
		FillPrintingButton();

		Items.GroupParameters.Show();
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Subsystem.Messages.Changed" Or pEventName = "MessageWrite" Then
		FillTasksPresentation();
	ElsIf pEventName = "Document.Folio.Edit" And pSource = Items.Folio 
		And ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("DocumentRef.Folio") Then
		Object.Folio = pParameter;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If ValueIsFilled(Object.ParentDoc) And DoNotCheckOrderTime = False Then  
		pCancel = Not CheckOrderTime(Object.ParentDoc, Object.OrderTime);
		If pCancel Then	
			vNotify = New NotifyDescription("ContinueAfterCheckOrderTime", ThisObject, pWriteParameters);
			vTextQuery = Nstr("en = 'Date of service provided outside the guest''s period of stay, continue?'; 
							  |de = 'Datum der Leistungserbringung außerhalb der Aufenthaltsdauer des Gastes, fortfahren?'; 
							  |ru = 'Дата оказания услуги за пределами периода проживания гостя, продолжить?'");
			ShowQueryBox(vNotify, vTextQuery, QuestionDialogMode.YesNo, 0, DialogReturnCode.No);
		EndIf;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not ValueIsFilled(Object.Ref) Then
		For Each StatusRow In Object.Type.StatusesCourse Do
			If StatusRow.Status.isNewOrder And Not ValueIsFilled(Object.Status) Then
				Documents.Order.SetStatus(pCurrentObject, StatusRow.Status, True);
			EndIf;
			If StatusRow.Status.SetAuthor Then
				Documents.Order.SetStatus(pCurrentObject,StatusRow.Status,True);				
				pCurrentObject.Author = SessionParameters.CurrentUser;
				pCurrentObject.Status = StatusRow.Status;
			EndIf;
		EndDo;
	EndIf;
	EditForm();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	EditForm();
	// Printing button appearance
	If WasNew Then
		FillPrintingButton();
		WasNew = False;
		
		Items.GroupParameters.Show();
	EndIf;
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.Order.Write", Object.Ref);
	ChangeEnabledGetUnallocatedMedicalServices();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Transfer Then
		If Object.OrderPaymentType = Enums.OrderPaymentType.Employee Then
			If Not ValueIsFilled(Object.Employee) Then
				pCancel = True; 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Driver is not filled!'; ru='Не указан водитель!'; de='Kein Autofahrer angegeben!'"),,"Employee");
			EndIf;			
		EndIf;		
	EndIf;	
EndProcedure

#EndRegion  

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure OrderTimeYOnChange(pItem)
	If Object.OrderTime < BegOfDay(CurrentDate()) Then
		ShowMessageBox(, NStr("en = 'Order date is less than current date!'; ru = 'Дата заказа меньше чем текущая дата!'; de = 'Bestelldatum ist weniger als aktuelles Datum!'"));
	EndIf;
	PriceInService();
EndProcedure // OrderTimeYOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ItemsSumOnChange(pItem)
	If Items.Items.CurrentData.Price = 0 And Items.Items.CurrentData.Sum <> 0 Then
		Items.Items.CurrentData.Price = Items.Items.CurrentData.Sum;
		Items.Items.CurrentData.Price = ?(Items.Items.CurrentData.Price < 0, -Items.Items.CurrentData.Price, Items.Items.CurrentData.Price);
	EndIf;
	If Items.Items.CurrentData.Price <> 0 Then
		Items.Items.CurrentData.Quantity = Items.Items.CurrentData.Sum/Items.Items.CurrentData.Price;
	Else
		Items.Items.CurrentData.Quantity = 1;
	EndIf;
	CalculateTotalsAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetPrice(pItem)
	Return pItem.Price;
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure ItemsItemOnChange(pItem)
	vCurData = Items.Items.CurrentData;
	If vCurData <> Undefined Then
		vCurData.Price = GetPrice(Items.Items.CurrentData.Item);
		If vCurData.Quantity = 0 Then
			vCurData.Quantity = 1;
		EndIf;
		vCurData.Sum = vCurData.Quantity * vCurData.Price;
	EndIf;
	CalculateTotalsAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(pItem)
	Object.Service = Undefined;
	TypeOnChangeAtServer();
	CheckExternalSystem();
	ChangeEnabledGetUnallocatedMedicalServices();
	If WasNew And ValueIsFilled(Object.Client) And ValueIsFilled(ExternalSystem) Then
		GetUnallocatedMedicalServicesAtServer();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ItemsOnChange(Item)
	SetSumm();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	FillParentDocByRoom();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	FillParentDocByClient();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ServicesOnChange(pItem)
	ServicesOnChangeAtServer();
	PriceInService();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	If Not IsBlankString(Object.Phone) Then
		Object.Phone = GetValidPhoneNumberAtServer(TrimAll(Object.Phone));
		If Not ValueIsFilled(Object.Client) Then
			Object.Client = GetClientByPhoneAtServer(TrimAll(Object.Phone));
			ClientOnChange(Items.Client);
		EndIf;
	EndIf;
EndProcedure // PhoneOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure QuantityOnChange(pItem)
	PriceInService();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RentTimeOnChange(pItem)
	Object.Quantity  = ?(Object.RentTime > 0, Object.RentTime, 1);
	PriceInService();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	GuestGroupOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task(Commands.Task);
EndProcedure // DecorationTasksClick

// --------------------------------------------------------------------------------
&AtClient
Procedure Click(pItem) 
	If Not ReadOnly Then
		If Not Items.GroupStatus.ReadOnly Then
			vStatusName = Mid(pItem.Title, Find(pItem.Title, ".") + 2, StrLen(pItem.Title) - Find(pItem.Title, "."));
			Status = GetStatus(vStatusName);
			If Object.Status <> Status Then
				vNotify = New NotifyDescription("Attachable_SetNewStatus", ThisObject, Status);	
				vQueryString = StrTemplate(NStr("en = 'Are you sure you want to change the status of the current document to ""%1""?'; 
												|de = 'Sind Sie sicher, dass Sie den Status des aktuellen Dokuments auf ""%1"" ändern möchten?'; 
												|ru = 'Хотите изменить статус текущего документа на ""%1""?'"), String(Status));
				ShowQueryBox(vNotify, vQueryString, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, NStr("en = 'Change document status'; ru = 'Смена статуса документа'; de = 'Änderungsbelegstatus'")); 
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Order charge is canceled! Order is read only.'; 
															|de = 'Bestellgebühr wird storniert! Die Bearbeitung einer solchen Bestellung ist verboten.'; 
															|ru = 'Начисление этого заказа отменено! Редактирование такого заказа запрещено.'"));
		EndIf;
	EndIf;
EndProcedure                                                   

// --------------------------------------------------------------------------------
&AtClient
Procedure RouteTypeOnChange(pItem)
	RouteTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DestinationOnChange(pItem)
	GetTransferPrice();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CarTypeOnChange(pItem)
 	GetTransferPrice();
	FillTransferRoute();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OrderPaymentTypeOnChange(pItem)
	OrderPaymentTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure WhereFromOnChange(pItem)
	GetTransferPrice();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(pItem)
	FillOrderPaymentTypeList();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ManualDiscountTypeOnChange(Item)
	ManualDiscountTypeOnChangeAtServer();
	CalculateManualDiscount();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ManualDiscountOnChange(Item)
	CalculateManualDiscount();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ManualDiscountSumOnChange(Item)
	CalculateManualDiscount();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(Item)
	ClientTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FolioCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vDateTimeFrom = '00010101';
	vDateTimeTo = '00010101';
	vParentDoc = Object.ParentDoc;
	If Not ValueIsFilled(vParentDoc) Then
		vParentDoc = Object.Folio;
	EndIf;
	If ValueIsFilled(vParentDoc) Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			vDateTimeFrom = tcOnServer.cmGetAttributeByRef(vParentDoc, "CheckInDate");
			vDateTimeTo = tcOnServer.cmGetAttributeByRef(vParentDoc, "CheckOutDate");
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Or TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
			vDateTimeFrom = tcOnServer.cmGetAttributeByRef(vParentDoc, "DateTimeFrom");
			vDateTimeTo = tcOnServer.cmGetAttributeByRef(vParentDoc, "DateTimeTo");
		EndIf;
	EndIf;
	OpenForm("Document.Folio.ObjectForm", New Structure("FillingValues", New Structure("Client, GuestGroup, ParentDoc, DateTimeFrom, DateTimeTo", Object.Client, Object.GuestGroup, vParentDoc, vDateTimeFrom, vDateTimeTo)), pItem, Object.Folio, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FolioCreating

// --------------------------------------------------------------------------------
&AtClient
Procedure FolioOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.Folio) Then
		OpenForm("Document.Folio.ObjectForm", New Structure("Key", Object.Folio), pItem, Object.Folio, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // pStandardProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	CalculateManualDiscount();
EndProcedure // PriceOnChange

#EndRegion     

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseOrder(pCommand)
	ShowQueryBox(New NotifyDescription("CloseOrderQuestionOnAnswer", ThisObject), NStr("en='Cancel this order?'; ru='Отменить этот заказ?'; de='Diese Bestellung stornieren?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // CloseOrder

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(pCommand)
	If CheckFilling() Then
		Write();
		
		vParam = New Structure;
		vParam.Insert("SetParamObject", Object.Room);
		vParam.Insert("SetOrder", 		Object.Ref);
		vParam.Insert("SetDepartment",  Object.Department);
		vParam.Insert("SetRemarks", 	Object.Remarks);
		
		vMessageType = tcOnServer.cmGetAttributeByRef(Object.Type, "MessageType");
		If ValueIsFilled(vMessageType) Then
			vParam.Insert("SetType", vMessageType);
			vType = tcOnServer.cmGetAttributeByRef(vMessageType, "Type");
			If ValueIsFilled(vType) Then
				vParam.Insert("Type", vType);
			EndIf;
		Else
			vParam.Insert("Type", PredefinedValue("Enum.MessageTypes.Task"));
		EndIf;
		OpenForm("Document.Message.Form.tcDocumentForm", vParam, ThisObject);
	EndIf;
EndProcedure // NewTask

// --------------------------------------------------------------------------------
&AtClient
Procedure Pay(pCommand)
	If ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Ref) Then
		// Open payment form
		#IF ThickClientOrdinaryApplication THEN
			vPayment = Documents.Payment.CreateDocument();
			vPayment.Fill(Object.Ref);
			vPayment.GetForm().Open();
		#ELSE
			OpenForm("Document.Payment.ObjectForm", New Structure("Basis, OrderNumber", Object.Ref, TrimAll(Object.Number)), ThisObject);
		#ENDIF
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	stParam = New Structure("SetParamObject", Object.Room);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtClient
Procedure GetPayment(Command)
	FillFolio();
	If Modified Then 
		Write();
	EndIf;	
	vList = CheckIfProformaInvoicesExist();
	If vList.Count() > 0 Then
		OpenGetPaidForm(vList[0].Value);
	Else
		OpenGetPaidForm();
	EndIf;
EndProcedure // GetPayment

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(Command)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vPrintNumber = StrReplace(Command.Name, "Print", "");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf Left(vPrintForm.PredefinedDataName, 10) = "OrderPrint" Then
	EndIf;
EndProcedure // PrintButtonClick

&AtClient
Procedure GetUnallocatedMedicalServices(pCommand)
	If CheckFilling() Then
		GetUnallocatedMedicalServicesAtServer();
	EndIf;
EndProcedure // GetUnallocatedMedicalServices

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillOrderTypesList()
	Items.Type.ChoiceList.Clear();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	OrderTypes.Ref
	|FROM
	|	Catalog.OrderTypes AS OrderTypes
	|WHERE
	|	NOT OrderTypes.DeletionMark";	
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		Items.Type.ChoiceList.Add(vSelectionDetailRecords.Ref);
	EndDo;
EndProcedure // FillOrderTypesList

// --------------------------------------------------------------------------------
&AtServer
Function CheckIfOrderChargeWasCanceled()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.Posted
	|	AND Storno.ParentCharge = &qCharge";
	vQry.SetParameter("qCharge", Object.Charge);
	vStornos = vQry.Execute().Unload();
	If vStornos.Count() > 0 Then
		Return True;
	EndIf;
	Return False;
EndFunction // CheckIfOrderChargeWasCanceled

// --------------------------------------------------------------------------------
&AtServer
Procedure EditForm()
	Items.GroupDocument.Title = NStr(tcCommonFunctions.cmSetTextParameters("en = 'Order № &p1 from &p2'; ru = 'Заказ № &p1 от &p2'; de = 'Bestellung № &p1 von &p2'",Object.Number,Object.Date));
	If ValueIsFilled(Object.Ref) Then
		Items.Type.ReadOnly = True;
	Else	
		Items.Type.ReadOnly = False;		
	EndIf;	
	If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.RoomService Then
		Items.RoomServiceGroup.Visible = True;	
		Items.TransferGroup.Visible    = False;	
		Items.RentGroup.Visible        = False;	
		Items.RentTime.Visible         = False;	
		Items.OrderDateTo.Visible      = False;	
		Items.GroupTime.Visible        = True;		
		Items.Quantity.Visible         = False;
		Items.Price.Visible            = False;
		Items.allGuestQuantity.Visible = True;
		
		If Object.Quantity = 0 Then
			Object.Quantity 		   = 1;
		EndIf;
	ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Transfer Then
		Items.RoomServiceGroup.Visible = False;	
		Items.TransferGroup.Visible    = True;	
		Items.RentGroup.Visible        = False;
		Items.RentTime.Visible         = False;	
		Items.OrderDateTo.Visible      = False;	
		Items.Quantity.Visible         = False;
		Items.Price.Visible            = True;
		Items.Price.ReadOnly		   = False;
		Items.GroupTime.Visible        = False;
		Items.allGuestQuantity.Visible = False;
		If Object.Quantity = 0 Then 
			Object.Quantity 		   = 1;
		EndIf;
	ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Rent Then
		Items.RoomServiceGroup.Visible = False;	
		Items.TransferGroup.Visible    = False;	
		Items.RentGroup.Visible        = False;	
		Items.RentTime.Visible         = True;
		Items.OrderDateTo.Visible      = True;	
		Items.Quantity.Visible         = True;
		Items.Quantity.ReadOnly        = True;
		Items.Price.Visible            = True;
		Items.Quantity.ReadOnly        = True;
		Items.OrderTimeH.Visible       = True;
		Items.OrderDateTo.Visible	   = False;
		Items.GroupTime.Visible        = True;
		Items.allGuestQuantity.Visible = True;
		
		If Object.Quantity <> Object.RentTime Then 
			Object.Quantity = Object.RentTime;
		EndIf;
		If Not ValueIsFilled(Object.OrderTime) Then
			Object.OrderTime = CurrentSessionDate();
		EndIf;
	ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.RentDaily Then
		Items.RoomServiceGroup.Visible = False;	
		Items.TransferGroup.Visible    = False;	
		Items.RentGroup.Visible        = False;	
		Items.RentTime.Visible         = True;
		Items.OrderDateTo.Visible      = True;	
		Items.Quantity.Visible         = True;
		Items.Quantity.ReadOnly        = True;
		Items.Price.Visible            = True;
		Items.OrderTimeH.Visible       = False;
		Items.OrderDateTo.Visible	   = True;
		Items.GroupTime.Visible        = True;	
		Items.allGuestQuantity.Visible = True;
		
		If Object.Quantity <> Object.RentTime Then 
			Object.Quantity = Object.RentTime;
		EndIf;
		If Not ValueIsFilled(Object.OrderTime) Then
			Object.OrderTime = CurrentSessionDate();
		EndIf;
	Else
		Items.RoomServiceGroup.Visible = False;	
		Items.TransferGroup.Visible    = False;	
		Items.RentGroup.Visible        = False;	
		Items.RentTime.Visible         = False;
		Items.OrderDateTo.Visible      = False;	
		Items.Quantity.Visible         = True;
		Items.Quantity.ReadOnly        = False;
		Items.Price.Visible            = True;
		Items.Price.ReadOnly           = False;
		Items.GroupTime.Visible        = True;	
		Items.allGuestQuantity.Visible = True;
		
		If Object.Quantity = 0 Then 
			Object.Quantity 		   = 1;
		EndIf;
	Endif;
	If  Object.Items.Count() > 0 Then
		// If Items are filled (from interfaces for example) we have to show the table anyway
		Items.RoomServiceGroup.Visible = True;	
	EndIf;
	FillServicesList();
	
	Items.FormPay.Visible = ValueIsFilled(Object.Folio);
	
	If Object.Status.isOrderCancel Or Object.Status.isOrderComplete Or Not ValueIsFilled(Object.Ref) Then
		Items.FormCloseOrder.Enabled = False;
	Else
		Items.FormCloseOrder.Enabled = True;
	EndIf;
	
	FillOrderPaymentTypeList();
	CreateProgressBar();	
	FillTasksPresentation();
	VisibilityDiscountTypeManagement();
	
	// Items enabled
	If ValueIsFilled(Object.Status) And Object.Status.DoNotAllowEditOfMainParameters Then
		Items.Type.Enabled 					= False;
		Items.Client.Enabled 				= False;
		Items.Room.Enabled 					= False;
		Items.GuestGroup.Enabled 			= False;
		Items.RouteType.Enabled 			= False;
		Items.CarType.Enabled 				= False;
		Items.WhereFrom.Enabled 			= False;
		Items.Destination.Enabled 			= False;
		Items.OrderTimeY1.Enabled 			= False;
		Items.OrderTimeH1.Enabled 			= False;
		Items.OrderTimeY.Enabled 			= False;
		Items.OrderTimeH.Enabled 			= False;
		Items.Service.Enabled 				= False;
		Items.RentResources.Enabled 		= False;
		Items.GroupManualDiscount.Enabled 	= False;
		Items.GroupPayment.Enabled 			= False;
		Items.Quantity.Enabled 				= False;
		Items.Price.Enabled 				= False;
		Items.Department.Enabled 			= False;
		Items.Manager.Enabled 				= False;
	Else
		Items.Type.Enabled 					= True;
		Items.Client.Enabled 				= True;
		Items.Room.Enabled 					= True;
		Items.GuestGroup.Enabled 			= True;
		Items.RouteType.Enabled 			= True;
		Items.CarType.Enabled 				= True;
		Items.WhereFrom.Enabled 			= True;
		Items.Destination.Enabled 			= True;
		Items.OrderTimeY1.Enabled 			= True;
		Items.OrderTimeH1.Enabled 			= True;
		Items.OrderTimeY.Enabled 			= True;
		Items.OrderTimeH.Enabled 			= True;
		Items.Service.Enabled 				= True;
		Items.RentResources.Enabled 		= True;
		Items.GroupManualDiscount.Enabled 	= True;
		Items.GroupPayment.Enabled 			= True;
		Items.Quantity.Enabled 				= True;
		Items.Price.Enabled 				= True;
		Items.Department.Enabled 			= True;
		Items.Manager.Enabled 				= True;
	EndIf;
	If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Transfer Then
		RouteTypeView();
	EndIf;
	
	// Check state
	If Not ReadOnly Then
		vObj = FormAttributeToValue("Object");
		If Not vObj.pmIfModificationIsAllowed() Then
			ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // EditForm

// --------------------------------------------------------------------------------
&AtServer
Procedure TypeOnChangeAtServer()
	If ValueIsFilled(Object.Type.Department) Then
		Object.Department = Object.Type.Department; 
	EndIf;
	If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.AdditionalServices Then
		If ValueIsFilled(Object.ParentDoc) Then
			Object.OrderTime = BegOfDay(Object.ParentDoc.CheckInDate);   
		EndIf; 
		Object.Employee = Undefined;
	ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Transfer Then
		RouteTypeOnChangeAtServer();    
	ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.RoomService Then 
		Object.OrderTime = BegOfDay(CurrentSessionDate());	
	Else 
		Object.Employee = Undefined;
	EndIf;
	
	EditForm();
EndProcedure // TypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillServicesList()
	Items.Service.ChoiceList.Clear();
	If Object.Type.ServicesAllowed.Count() > 0 Then
		For Each vRowServicesAllowed In Object.Type.ServicesAllowed Do
			vSevice = vRowServicesAllowed.Service;
			If vSevice.Hotel.IsEmpty() Or vSevice.Hotel = Object.Hotel Then
				Items.Service.ChoiceList.Add(vRowServicesAllowed.Service);
			EndIf;
		EndDo;
		If Not ValueIsFilled(Object.Service) Then
			If Items.Service.ChoiceList.Count() > 0 Then  
				Object.Service = Items.Service.ChoiceList[0].Value;
			EndIf;
			ServicesOnChangeAtServer();
			PriceInService();
			CalculateManualDiscount();
		EndIf;
	EndIf;
EndProcedure // FillServicesList

// --------------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsAtServer()
	vObj = FormAttributeToValue("Object");
	If vObj.Items.Count() > 0 Then
		vObj.Quantity = 1;
		vObj.Price = vObj.Items.Total("Sum");
	EndIf;
	vObj.pmSetDiscounts();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CalculateTotalsAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SetSumm()
	vCurData = Items.Items.CurrentData;
	If vCurData <> Undefined Then
		vCurData.Sum = vCurData.Quantity * vCurData.Price;
	EndIf;
	CalculateTotalsAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function CloseOrderAtServer()
	vErrorDescription = "";
	vSavStatus = Object.Status;
	Object.Status = Catalogs.OrderStatuses.Cancel;
	Try
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			vErrorDescription = NStr("en='Failed to change order status! It is possible that order either is in closed date or belongs to checked-out guest.'; 
			                         |ru='Не удалось изменить статус заказа! Возможно заказ в закрытой дате или принадлежит выселенному гостю.'; 
									 |de='Bestellstatus konnte nicht geändert werden! Es ist möglich, dass die Bestellung entweder geschlossen ist oder dem ausgecheckten Gast gehört.'");
		EndIf;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If IsBlankString(vErrorDescription) Then
			vErrorDescription = NStr("en='Failed to change order status! It is possible that order either is in closed date or belongs to checked-out guest.'; 
			                         |ru='Не удалось изменить статус заказа! Возможно заказ в закрытой дате или принадлежит выселенному гостю.'; 
									 |de='Bestellstatus konnte nicht geändert werden! Es ist möglich, dass die Bestellung entweder geschlossen ist oder dem ausgecheckten Gast gehört.'");
		EndIf;
		Object.Status = vSavStatus;
		ThisObject.Modified = True;
	EndTry;
	CreateProgressBar();
	Return vErrorDescription;
EndFunction // CloseOrderAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillRoomAndPhone(pFillGuest = False, pFillPhone = False)
	If ValueIsFilled(Object.Room) Then
		If Object.Hotel <> Object.Room.Owner Then
			Object.Hotel = Object.Room.Owner;
		EndIf;		
		vGuestList = GetOneRoomAccommodations(Object.Room);
		vFirst = True;
		
		For Each vRow In vGuestList Do
			If vFirst Then
				If pFillGuest Then
					Object.Client = vRow.Guest;
				EndIf;
				If ValueIsFilled(Object.Client) And Object.Client = vRow.Guest And pFillPhone Then
					If Not IsBlankString(vRow.Phone) Then
						Object.Phone  = vRow.Phone;	
					EndIf;
					vFirst = False;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
	Else
		If pFillPhone Then
			If ValueIsFilled(Object.Client) And Not IsBlankString(Object.Client.Phone) Then
				Object.Phone = Object.Client.Phone;	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillRoomAndPhone

// --------------------------------------------------------------------------------
&AtServer
Function GetOneRoomAccommodations(pRoom) 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref,
	|	Docs.Guest,
	|	CASE
	|		WHEN Docs.Phone <> """"
	|			THEN Docs.Phone
	|		ELSE Docs.Guest.Phone
	|	END AS Phone,
	|	CASE
	|		WHEN Docs.Phone <> """"
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN Docs.Guest.Phone <> """"
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS PhoneFild
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.AccommodationStatus.IsInHouse
	|
	|ORDER BY
	|	PhoneFild DESC,
	|	Docs.CheckInDate,
	|	Docs.AccommodationType.SortCode,
	|	Docs.GuestFullName";
	vQry.SetParameter("qRoom", pRoom);
	vOneRoomDocs = vQry.Execute().Unload();
	Return vOneRoomDocs;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure FillParentDocByClient()
	If ValueIsFilled(Object.Client) Then
		Object.GuestsQuantity = 0;
		vQuery = New Query; 
		vQuery.Text = "SELECT
		|	Accommodation.Ref,
		|	Accommodation.GuestGroup,
		|	Accommodation.CheckInDate,
		|	Accommodation.CheckOutDate,
		|	Accommodation.Room
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.Guest = &qGuest
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.Hotel = &qHotel
		|	";
		If ValueIsFilled(Object.GuestGroup) Then
			vQuery.Text = vQuery.Text + "AND Accommodation.GuestGroup = &qGuestGroup
			| 	";
			vQuery.SetParameter("qGuestGroup", Object.GuestGroup);
		EndIf;
		vQuery.Text = vQuery.Text + "ORDER BY
		|	Accommodation.Date DESC";		
		vQuery.SetParameter("qGuest", Object.Client);
		vQuery.SetParameter("qHotel", Object.Hotel);
		
		vQueryResult = vQuery.Execute();		
		vSelectionDetailRecords = vQueryResult.Select();
		If vSelectionDetailRecords.Next() Then
			Object.ParentDoc  = vSelectionDetailRecords.ref;	
			Object.Room       = vSelectionDetailRecords.Room;	
			Object.GuestGroup = vSelectionDetailRecords.GuestGroup;				
			Object.RouteType  = Enums.RouteType.Departure;
			vOneRoomAccs = cmGetOneRoomAccommodations(Object.Room, Object.GuestGroup, vSelectionDetailRecords.CheckInDate, vSelectionDetailRecords.CheckOutDate);
			Object.GuestsQuantity = vOneRoomAccs.Count();
			FillOrderPaymentTypeList();
		Else
			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	Reservation.Ref,
			|	Reservation.GuestGroup,
			|	Reservation.CheckInDate,
			|	Reservation.CheckOutDate,
			|	Reservation.Room
			|FROM
			|	Document.Reservation AS Reservation
			|WHERE
			|	NOT Reservation.DeletionMark
			|	AND Reservation.Posted
			|	AND Reservation.Guest = &qGuest
			|	AND Reservation.ReservationStatus.IsActive
			|	AND Reservation.Hotel = &qHotel
			|	";
			If ValueIsFilled(Object.GuestGroup) Then
				vQuery.Text = vQuery.Text + "AND Reservation.GuestGroup = &qGuestGroup
				| 	";
				vQuery.SetParameter("qGuestGroup", Object.GuestGroup);
			EndIf;
			vQuery.Text = vQuery.Text + "ORDER BY			
			|	Reservation.Date DESC";		
			vQuery.SetParameter("qGuest", Object.Client);
			vQuery.SetParameter("qHotel", Object.Hotel);
			
			vQueryResult = vQuery.Execute();		
			vSelectionDetailRecords = vQueryResult.Select();
			IF vSelectionDetailRecords.Next() Then
				Object.ParentDoc  = vSelectionDetailRecords.ref;	
				Object.Room       = vSelectionDetailRecords.Room;	
				Object.GuestGroup = vSelectionDetailRecords.GuestGroup;
				Object.RouteType  = Enums.RouteType.Arrive;
				vOneRoomRes = cmGetOneRoomReservations(TrimAll(Object.ParentDoc.Number), Object.GuestGroup, vSelectionDetailRecords.CheckInDate, vSelectionDetailRecords.CheckOutDate);
				Object.GuestsQuantity = vOneRoomRes.Count();
				FillOrderPaymentTypeList();
			Else
				Object.ParentDoc = Undefined;
			EndIf;			
		EndIf;
		// Fill client type
		If ValueIsFilled(Object.ParentDoc) Then
			If ValueIsFilled(Object.ParentDoc.ClientType) Then
				Object.ClientType = Object.ParentDoc.ClientType;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.Client) Then
			If ValueIsFilled(Object.Client.ClientType) Then
				Object.ClientType = Object.Client.ClientType;
			EndIf;
			If ValueIsFilled(Object.Client.DiscountCard) Then
				Object.DiscountCard = Object.Client.DiscountCard;
				If ValueIsFilled(Object.DiscountCard.ClientType) Then
					Object.ClientType = Object.DiscountCard.ClientType;
				EndIf;
			EndIf;
		EndIf;
	Else
		Object.ParentDoc  = Undefined;
		Object.GuestGroup = Undefined;
		Object.Room       = Undefined;
		FillOrderPaymentTypeList();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillParentDocByRoom()
	Items.Client.ListChoiceMode = False;
	If ValueIsFilled(Object.Room) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Accommodation.Ref,
		|	Accommodation.GuestGroup,
		|	Accommodation.Guest,
		|	Accommodation.AccommodationType.Code AS Code,
		|	Accommodation.AccommodationType.Description AS Description,
		|	Accommodation.Guest.FullName AS FullName
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.Room = &qRoom
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.Hotel = &qHotel
		|	";
		If ValueIsFilled(Object.GuestGroup) Then
			vQuery.Text = vQuery.Text + "AND Accommodation.GuestGroup = &qGuestGroup
			| 	";
			vQuery.SetParameter("qGuestGroup", Object.GuestGroup);
		EndIf;
		vQuery.Text = vQuery.Text + "ORDER BY
		|	Accommodation.Date DESC,
		|	Accommodation.AccommodationType.SortCode";		
		vQuery.SetParameter("qRoom", Object.Room);		
		vQuery.SetParameter("qHotel", Object.Hotel);
		vQueryResult = vQuery.Execute();		
		vSelectionDetailRecords = vQueryResult.Select();
		Object.GuestsQuantity = 0;
		If vSelectionDetailRecords.Count() > 0 Then
			If vSelectionDetailRecords.Count() = 1 Then
				While vSelectionDetailRecords.Next() Do
					Object.ParentDoc  = vSelectionDetailRecords.ref;	
					Object.Client      = vSelectionDetailRecords.Guest;	
					Object.GuestGroup = vSelectionDetailRecords.GuestGroup;					
					Object.GuestsQuantity = Object.GuestsQuantity + 1;
				EndDo;
			Else
				Items.Client.ChoiceList.Clear();
				While vSelectionDetailRecords.Next() Do	
					If ValueIsFilled(vSelectionDetailRecords.Guest) Then
						Items.Client.ChoiceList.Add(vSelectionDetailRecords.Guest,vSelectionDetailRecords.FullName + " - " + vSelectionDetailRecords.Description);
					EndIf;
					Object.GuestsQuantity = Object.GuestsQuantity + 1;
				EndDo;
				If Items.Client.ChoiceList.Count() > 0 Then
					Items.Client.ListChoiceMode = True;
				EndIf;
			EndIf;
			Object.RouteType = Enums.RouteType.Departure;
			RouteTypeOnChangeAtServer();
			FillOrderPaymentTypeList();
		Else
			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	Reservation.Ref,
			|	Reservation.GuestGroup,
			|	Reservation.Guest,
			|	Reservation.AccommodationType.Code AS Code,
			|	Reservation.AccommodationType.Description AS Description,
			|	Reservation.Guest.FullName AS FullName
			|FROM
			|	Document.Reservation AS Reservation
			|WHERE
			|	NOT Reservation.DeletionMark
			|	AND Reservation.Posted
			|	AND Reservation.Room = &qRoom
			|	AND Reservation.ReservationStatus.IsActive
			|	AND Reservation.Hotel = &qHotel
			|	";
			If ValueIsFilled(Object.GuestGroup) Then
				vQuery.Text = vQuery.Text + "AND Reservation.GuestGroup = &qGuestGroup
				| 	";
				vQuery.SetParameter("qGuestGroup", Object.GuestGroup);
			EndIf;
			vQuery.Text = vQuery.Text + "ORDER BY
			|	Reservation.Date DESC,
			|	Reservation.AccommodationType.SortCode";		
			vQuery.SetParameter("qRoom", Object.Room);
			vQuery.SetParameter("qHotel", Object.Hotel);
			vQueryResult = vQuery.Execute();		

			vSelectionDetailRecords = vQueryResult.Select();
			Object.GuestsQuantity = 0;
			If vSelectionDetailRecords.Count() > 0 Then
				If vSelectionDetailRecords.Count() = 1 Then
					While vSelectionDetailRecords.Next() Do
						Object.ParentDoc  = vSelectionDetailRecords.ref;	
						Object.Client      = vSelectionDetailRecords.Guest;	
						Object.GuestGroup = vSelectionDetailRecords.GuestGroup;					
						Object.GuestsQuantity = Object.GuestsQuantity + 1;
					EndDo;
				Else
					Items.Client.ChoiceList.Clear();
					While vSelectionDetailRecords.Next() Do	
						If ValueIsFilled(vSelectionDetailRecords.Guest) Then
							Items.Client.ChoiceList.Add(vSelectionDetailRecords.Guest,vSelectionDetailRecords.FullName + " - " + vSelectionDetailRecords.Description);
						EndIf;
						Object.GuestsQuantity = Object.GuestsQuantity + 1;
					EndDo;
					If Items.Client.ChoiceList.Count() > 0 Then
						Items.Client.ListChoiceMode = True;
					EndIf;
				EndIf;
				Object.RouteType = Enums.RouteType.Arrive;;
				RouteTypeOnChangeAtServer();
				FillOrderPaymentTypeList();
			Else
				Object.ParentDoc = Undefined;	
			EndIf;			
		EndIf;
		// Fill client type
		If ValueIsFilled(Object.ParentDoc) Then
			If ValueIsFilled(Object.ParentDoc.ClientType) Then
				Object.ClientType = Object.ParentDoc.ClientType;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.Client) Then
			If ValueIsFilled(Object.Client.ClientType) Then
				Object.ClientType = Object.Client.ClientType;
			EndIf;
			If ValueIsFilled(Object.Client.DiscountCard) Then
				Object.DiscountCard = Object.Client.DiscountCard;
				If ValueIsFilled(Object.DiscountCard.ClientType) Then
					Object.ClientType = Object.DiscountCard.ClientType;
				EndIf;
			EndIf;
		EndIf;
	Else
		Object.ParentDoc = Undefined;
		Object.GuestGroup = Undefined;
		Object.Client = Undefined;
		FillOrderPaymentTypeList();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDepartmentsList()
	Items.Department.ChoiceList.Clear();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Departments.Ref
	|FROM
	|	Catalog.Departments AS Departments
	|WHERE
	|	NOT Departments.IsFolder
	|	AND NOT Departments.DeletionMark";
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		Items.Department.ChoiceList.Add(vSelectionDetailRecords.Ref);
	EndDo;
EndProcedure // FillDepartmentsList

// --------------------------------------------------------------------------------
&AtServer
Procedure ServicesOnChangeAtServer()
	If ValueIsFilled(Object.Service) Then
		Object.Unit = TrimAll(Object.Service.Unit);
		Items.Quantity.Title = Object.Service.Unit;
		Object.Quantity  = ?(Object.RentTime > 0, Object.RentTime, 1);
		vParentDoc = Object.ParentDoc;
		// Quantity calculation for additional services
		If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.AdditionalServices And ValueIsFilled(Object.Service.QuantityCalculationRule) And ValueIsFilled(vParentDoc) Then
			vCurDate = BegOfDay(vParentDoc.CheckInDate);
			vQ = 0;
			While vCurDate <= BegOfDay(vParentDoc.CheckOutDate) Do
			     vQty  = cmCalculateServiceQuantity(Object.Service, Object.Service.QuantityCalculationRule, vCurDate, vParentDoc.CheckInDate, vParentDoc.CheckOutDate);
				 vQ = vQ + vQty;
				 vCurDate = vCurDate + 86400; // add one day
			EndDo;
			If vQ > 0 Then
				Object.Quantity = vQ;
			EndIf;	
		EndIf;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllPriceChangeReasons()
	vPCRTable = cmGetAllPriceChangeReasons();
	vPCRArray = vPCRTable.UnloadColumn("Description");
	Return vPCRArray;
EndFunction // GetArrayOfAllPriceChangeReasons

// --------------------------------------------------------------------------------
&AtServer
Procedure PriceInService()
	If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Transfer Then
		Object.Unit = "";
		GetTransferPrice();
	Else
		If ValueIsFilled(Object.OrderTime) Then
			If ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.Rent Then
				Object.OrderDateFrom = BegOfDay(Object.OrderTime);
				Object.OrderDateTo = BegOfDay(Object.OrderTime + Object.RentTime * 3600);
			ElsIf ValueIsFilled(Object.Type) And Object.Type.Type = Enums.TypesOfOrder.RentDaily Then
				Object.OrderDateFrom = BegOfDay(Object.OrderTime);
				Object.OrderDateTo = BegOfDay(Object.OrderTime + Object.RentTime * 3600 * 24);
			Else
				Object.OrderDateFrom = BegOfDay(Object.OrderTime);
				Object.OrderDateTo = '00010101';
			EndIf;
		Else
			Object.OrderDateFrom = '00010101';
			Object.OrderDateTo = '00010101';
		EndIf;
		
		If ValueIsFilled(Object.Service) Then
			Object.Unit = TrimAll(Object.Service.Unit);
			If Object.Quantity > 0 Then
				If ValueIsFilled(Object.ParentDoc) Then
					If TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") Then
						vClientType = Object.ParentDoc.ClientType;
					ElsIf TypeOf(Object.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
						vClientType = Object.ParentDoc.ClientType;
					ElsIf TypeOf(Object.ParentDoc) = Type("DocumentRef.Folio") Then
						vClientType = Object.ParentDoc.ParentDoc.ClientType;
					EndIf;  
				EndIf;
				vDateTo = Object.Date;
				If Object.Type.FillPricesByOrderTime Then
					vDateTo = Object.OrderTime;
				EndIf;	
				If Not ValueIsFilled(vDateTo) Then
					vDateTo = CurrentSessionDate();
				EndIf;
                vServiceObject = Object.Service.GetObject();
				vPrice = vServiceObject.pmGetServicePrices(Object.Hotel, vDateTo, vClientType);
				If vPrice.Count() > 0 Then
					Object.Price = vPrice[0].Price;
					Object.Currency = vPrice[0].Currency;
					CalculateTotalsAtServer();
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency = Object.Hotel.BaseCurrency;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseOrderQuestionOnAnswer(pDialogReturnCode, pExtraParams) Export
	If pDialogReturnCode = DialogReturnCode.Yes Then
		vErrorDescription = CloseOrderAtServer();
		If Not IsBlankString(vErrorDescription) Then
			ShowMessageBox(, vErrorDescription);
		Else
			Notify("Document.Order.Write", Object.Ref);
			Close();
		EndIf;
	EndIf;
EndProcedure // CloseOrderQuestionOnAnswer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetValidPhoneNumberAtServer(pPhone)
	Return SMS.GetValidPhoneNumber(pPhone);
EndFunction // GetValidPhoneNumberAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetClientByPhoneAtServer(pPhone)
	Return cmGetClientByPhone(pPhone);
EndFunction // GetClientByPhoneAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	#IF NOT WebClient THEN
		If StrLen(pText) > 2 Then
			vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
			pChoiceData = GetFromTempStorage(vChoiceDataUID);
			If pChoiceData.Count() = 0 Then
				pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
			EndIf;
		EndIf;
	#ELSE
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#ENDIF
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	If ValueIsFilled(Object.GuestGroup) Then
		Object.Client = Object.GuestGroup.Client;
		FillParentDocByClient();		
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillOrderPaymentTypeList()
	Items.OrderPaymentType.ChoiceList.Clear();
	If ValueIsFilled(Object.OrderPaymentType) And ValueIsFilled(Object.Charge) Then
		Items.OrderPaymentType.ChoiceList.Add(Object.OrderPaymentType);
	Else
		Items.OrderPaymentType.ChoiceList.Add(Enums.OrderPaymentType.Cash);
		If ValueIsFilled(Object.ParentDoc) Then
			Items.OrderPaymentType.ChoiceList.Add(Enums.OrderPaymentType.Room);
		EndIf;
		If ValueIsFilled(Object.Employee) Then
			Items.OrderPaymentType.ChoiceList.Add(Enums.OrderPaymentType.Employee);
		EndIf;
	EndIf;
EndProcedure // FillOrderPaymentTypeList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFolio() 
	If Object.Folio.IsEmpty() Then
		vDocumentObject = FormAttributeToValue("Object");
		Object.Folio = vDocumentObject.pmFillFolio();
		Write();
	EndIf;
EndProcedure //  FillFolio

// -----------------------------------------------------------------------------
&AtServer
Function CreateNewOrEditProformaInvoice(pDocRef)
	If Not pDocRef = Undefined Then
		vProformaInvoice = pDocRef.GetObject();
	Else
		vProformaInvoice = Documents.ProformaInvoice.CreateDocument(); 
	EndIf;
	vProformaInvoice.Fill(Object.Ref); 
	vProformaInvoice.Write(DocumentWriteMode.Posting);
	Return vProformaInvoice.Ref;
EndFunction //  CreateNewOrEditProformaInvoice

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfProformaInvoicesExist()
	vQuery = New Query();
	vQuery.Text =
	"SELECT TOP 1
	|	DocumentInvoice.Ref AS Description,
	|	DocumentInvoice.Date AS Date
	|FROM
	|	Document.ProformaInvoice AS DocumentInvoice
	|WHERE
	|	DocumentInvoice.Posted
	|	AND DocumentInvoice.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	Date DESC";

	vQuery.SetParameter("qParentDoc", Object.Ref);
	vResult = vQuery.Execute().Unload();
	vValueList = New ValueList;
	For Each vRow In vResult Do
		vValueList.Add(vRow.Description);
	EndDo;
	Return vValueList;
EndFunction //  CheckIfProformaInvoicesExist

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenGetPaidForm(pDocRef = Undefined)
	vDocRef = CreateNewOrEditProformaInvoice(pDocRef);
	vDocForm = GetForm("Document.ProformaInvoice.Form.tcDocumentForm", new Structure("DocRef", vDocRef));
	vParams = New Structure("SelDocument", vDocRef);
	OpenForm("CommonForm.tcGetPaidForm", vParams, vDocForm, vDocForm.UUID);
EndProcedure //  OpenGetPaidForm

// --------------------------------------------------------------------------------
&AtServer
Function FillMessageList()
	If ValueIsFilled(Object.Ref) Then
		pQuery = New Query;
		pQuery.Text = 
		"SELECT
		|	Message.Ref,
		|	Message.MessageStatus,
		|	Message.Remarks,
		|	Message.IsClosed
		|FROM
		|	Document.Message AS Message
		|WHERE
		|	Message.ByOrder = &ByOrder
		|	AND NOT Message.DeletionMark
		|	AND Message.Posted";
		pQuery.SetParameter("ByOrder", Object.Ref);
		QueryResult = pQuery.Execute().Unload();
		Return QueryResult;
	EndIf
EndFunction // FillMessageList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = FillMessageList();
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
EndProcedure // FillTasksPresentation

// --------------------------------------------------------------------------------
&AtClient
Procedure Attachable_SetNewStatus(pResult, pParam) Export 
	If pResult = DialogReturnCode.Yes Then
		SetNewStatusServer(pParam);
		ChangeEnabledGetUnallocatedMedicalServices();
	EndIf;
EndProcedure 

// --------------------------------------------------------------------------------
&AtServer
Procedure CreateProgressBar()
	vItemCount = Items.GroupStatus.ChildItems.Count() - 1;
	For x = 0 To vItemCount Do                           
		Items.Delete(Items.GroupStatus.ChildItems[0]);
	EndDo;
	
	vFinishColor = WebColors.Gainsboro;
	vCurrColor   = WebColors.Gainsboro;
	vNextColor   = New Color(255,255,255);
	
	v1Pic     = PictureLib.OrderArrowProgressBar;
	v2Pic     = PictureLib.OrderArrowProgressBar;	
	v3Pic     = PictureLib.OrderArrowProgressBar;
	v4Pic     = PictureLib.OrderArrowProgressBar;
	
	vStatusNumber = 1;
	vItemNumber = 1;
	vNextStatus = False;
	
	If ValueIsFilled(Object.Type) Then 
		If Object.Status.PredefinedDataName = "Cancel" Then
			CreateLable("BarItem" + vItemNumber,"0. " + String(Object.Status),Items.GroupStatus,vCurrColor,True,True);
			vItemNumber = vItemNumber + 1;
			CreatePic("BarItem" + vItemNumber,v3Pic,Items.GroupStatus,vCurrColor);
			vItemNumber = vItemNumber + 1;
		EndIf;
		For Each vStatus In Object.Type.StatusesCourse Do			
			If Not ValueIsFilled(Object.Status) Or Object.Status.PredefinedDataName = "Cancel" Then
				If vStatus.Status.isOrderComplete Then
					CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vNextColor,,True);
					vItemNumber = vItemNumber + 1;
				Else				
					CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vNextColor,,True);
					vItemNumber = vItemNumber + 1;
					CreatePic("BarItem" + vItemNumber,v4Pic,Items.GroupStatus,vNextColor);
					vItemNumber = vItemNumber + 1;
				EndIf;
			Else
				If vStatus.Status = Object.Status Then 
					If vStatus.Status.isOrderComplete Then
						CreatePic("BarItem" + vItemNumber,v1Pic,Items.GroupStatus,vFinishColor);	
						vItemNumber = vItemNumber + 1;						
						CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vFinishColor,True,True);
						vItemNumber = vItemNumber + 1;	
					ElsIf vStatus.Status.isNewOrder Then
						CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vCurrColor,True,True);
						vItemNumber = vItemNumber + 1;	
						CreatePic("BarItem" + vItemNumber,v3Pic,Items.GroupStatus,vCurrColor);
						vItemNumber = vItemNumber + 1;
					Else
						CreatePic("BarItem" + vItemNumber,v2Pic,Items.GroupStatus,vCurrColor);	
						vItemNumber = vItemNumber + 1;
						CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vCurrColor,True,True);  
						vItemNumber = vItemNumber + 1;
						CreatePic("BarItem" + vItemNumber,v3Pic,Items.GroupStatus,vNextColor);
						vItemNumber = vItemNumber + 1;
					EndIf;
					vNextStatus = True;
				Else
					If vNextStatus Then
						If vStatus.Status.isOrderComplete Then
							CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vNextColor);
							vItemNumber = vItemNumber + 1;							
						Else
							CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vNextColor);
							vItemNumber = vItemNumber + 1;
							CreatePic("BarItem" + vItemNumber,v4Pic,Items.GroupStatus,vNextColor);
							vItemNumber = vItemNumber + 1;
						EndIf;
					Else
						If vItemNumber = 1 Then
							CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vFinishColor);
							vItemNumber = vItemNumber + 1;							
						Else							
							CreatePic("BarItem" + vItemNumber,v1Pic,Items.GroupStatus,vFinishColor);						
							vItemNumber = vItemNumber + 1;						
							CreateLable("BarItem" + vItemNumber,String(vStatusNumber) + ". " + String(vStatus.Status),Items.GroupStatus,vFinishColor);
							vItemNumber = vItemNumber + 1;
						EndIf;
					EndIf;	
				EndIf;				
			EndIf;
			vStatusNumber = vStatusNumber + 1;
		EndDo;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CreateLable(pName, pTitle, pParent, pColor, pBold = False, pCurrent = False)
	vItemGroup = CreateGroup("Group"+pName,pParent,pColor);
	
	vItem = Items.Add(pName, Type("FormDecoration"), vItemGroup);
	vItem.Title = pTitle;
	vItem.BackColor = pColor;	
	vItem.Height = 0;	
	vItem.Hyperlink = True;
	vItem.Font = tcCommonFunctionOnClientServer.FontConstructor("Calibri Light", 12, pBold);
	vItem.TextColor = tcCommonFunctionOnClientServer.ColorConstructor();
	vItem.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	vItem.VerticalAlignInGroup = ItemVerticalAlign.Center;
	If ValueIsFilled(Object.Ref) Then
		vItem.SetAction("Click", "Click");
	EndIf;
	If pCurrent Then
		vItem.Border = New Border(ControlBorderType.Single, 1);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function CreateGroup(pName,pParent,pColor)
	vItemGroup = Items.Add("Group"+pName,Type("FormGroup"),pParent);
	vItemGroup.Type = FormGroupType.UsualGroup;
	vItemGroup.ShowTitle = False;
	vItemGroup.BackColor = pColor;
	vItemGroup.ChildItemsVerticalAlign = ItemVerticalAlign.Center; 
	vItemGroup.VerticalAlignInGroup = ItemVerticalAlign.Center; 
	vItemGroup.Representation = UsualGroupRepresentation.None;
	vItemGroup.VerticalStretch = True;	
	Return vItemGroup;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure CreatePic(pName, pPic, pParent, pColor)
	vItemGroup = CreateGroup("Group"+pName,pParent,pColor);
	
	vItem = Items.Add(pName,Type("FormDecoration"), vItemGroup);	
	vItem.Type = FormDecorationType.Picture;
	vItem.Picture     = pPic;
	vItem.Height      = 0;
	vItem.Width       = 0;
	vItem.MaxHeight   = 0;
	vItem.MaxWidth    = 0;
	vItem.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	vItem.VerticalAlignInGroup   = ItemVerticalAlign.Center;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function SetNewStatusServer(pStatus)
	Documents.Order.SetStatus(Object, pStatus, True, False);	
	EditForm();
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetStatus(pString)
	Return Catalogs.OrderStatuses.FindByDescription(pString)
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure RouteTypeView()
	If Object.RouteType = Enums.RouteType.Arrive Then
		Items.Destination.ReadOnly = True;
		Items.WhereFrom.ReadOnly   = False;
	ElsIf Object.RouteType = Enums.RouteType.Departure Then	
		Items.Destination.ReadOnly = False;
		Items.WhereFrom.ReadOnly   = True;	
	ElsIf Object.RouteType = Enums.RouteType.Route Then
		Items.Destination.ReadOnly = False;
		Items.WhereFrom.ReadOnly   = False;	
	EndIf;
EndProcedure // RouteTypeView

// --------------------------------------------------------------------------------
&AtServer
Procedure RouteTypeOnChangeAtServer()
	If Not ValueIsFilled(Object.RouteType) Then
		Object.RouteType = Enums.RouteType.Arrive;
	EndIf;
	RouteTypeView();
	If Object.RouteType = Enums.RouteType.Arrive Then
		If ValueIsFilled(Object.Destination) Then
			Object.PickupFrom = Object.Destination;
		EndIf;
		Object.Destination = Object.Hotel.Description;
	ElsIf Object.RouteType = Enums.RouteType.Departure Then	
		If ValueIsFilled(Object.PickupFrom) Then
			Object.Destination = Object.PickupFrom;		
		EndIf;
		Object.PickupFrom = Object.Hotel.Description;
	ElsIf Object.RouteType = Enums.RouteType.Route Then
		Object.Destination = "";
		Object.PickupFrom   = "";
	EndIf;
	GetTransferPrice();
EndProcedure

// -------------------------------------------------------------------------------- 
&AtServer
Procedure FillTransferRoute()
	Items.Destination.ChoiceList.Clear();
	Items.WhereFrom.ChoiceList.Clear();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	TransferPrices.Destination
	|FROM
	|	InformationRegister.TransferPrices AS TransferPrices
	|WHERE
	|	TransferPrices.Hotel IN(&qHotel)
	|	AND TransferPrices.TransferType = &qTransferType
	|
	|GROUP BY
	|	TransferPrices.Destination";
	vHotels = New Array;
	vHotels.Add(Object.Hotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	vQuery.SetParameter("qHotel",vHotels);
	vQuery.SetParameter("qTransferType", Object.TransferType);
	
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();	
	While vSelectionDetailRecords.Next() Do
		If ValueIsFilled(vSelectionDetailRecords.Destination) Then
			Items.Destination.ChoiceList.Add(vSelectionDetailRecords.Destination);
			Items.WhereFrom.ChoiceList.Add(vSelectionDetailRecords.Destination);	
		EndIf;
	EndDo;
EndProcedure

// -------------------------------------------------------------------------------- 
&AtServer
Procedure GetTransferPrice()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.Order"));
	vObj.pmGetTransferPrice();
	ValueToFormAttribute(vObj,"Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure OrderPaymentTypeOnChangeAtServer()	
	If Object.OrderPaymentType = Enums.OrderPaymentType.Room And Not ValueIsFilled(Object.ParentDoc) Then	
		Object.OrderPaymentType = Enums.OrderPaymentType.Cash;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ManualDiscountTypeOnChangeAtServer()
	VisibilityDiscountTypeManagement();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure VisibilityDiscountTypeManagement()
	vDT = Object.ManualDiscountType;
	If ValueIsFilled(vDT) Then
		Items.ManualDiscountSum.Enabled = vDT.IsAmountDiscount;
		Items.ManualDiscount.Enabled 	= vDT.IsManualDiscount;
	Else
		Items.ManualDiscountSum.Enabled = False;
		Items.ManualDiscount.Enabled 	= False;
		If Object.ManualDiscount <> 0 Then
			Object.ManualDiscount = 0;
		EndIf;
		If Object.ManualDiscountSum <> 0 Then
			Object.ManualDiscountSum = 0;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CalculateManualDiscount()
	vMDT = Object.ManualDiscountType;
	vMD	 = Object.ManualDiscount;
	vMDS = Object.ManualDiscountSum;
	If ValueIsFilled(vMDT) And vMDT.IsManualDiscount And ValueIsFilled(Object.Service) And ValueIsFilled(Object.Hotel) And Not vMDT.IsAmountDiscount Then
		vDiscount = vMDT.GetObject().pmGetDiscount(Object.Date, Object.Service, Object.Hotel);
		Object.ManualDiscount = vDiscount;
		// Update amount
		vSum = Round(Object.Price * Object.Quantity, 2);
		vDiscountSum = Round(vSum*vDiscount/100, 2);
		Object.Sum = vSum - vDiscountSum;
	ElsIf Not ValueIsFilled(vMDT) And vMD <> 0 Then
		// Update amount
		vSum = Round(Object.Price * Object.Quantity, 2);
		vDiscountSum = Round(vSum*Object.Discount/100, 2);
		Object.Sum = vSum - vDiscountSum;
		Object.ManualDiscountSum = 0;
	ElsIf ValueIsFilled(vMDT) And vMDT.IsAmountDiscount Then
		// Update amount
		vSum = Round(Object.Price * Object.Quantity, 2);
		Object.Sum = vSum - vMDS;
		Object.ManualDiscount = 0;
	ElsIf Not ValueIsFilled(vMDT) Then
		// Update amount
		Object.Sum = Round(Object.Price * Object.Quantity, 2);
	EndIf;
EndProcedure //  CalculateManualDiscount() 

// --------------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.Order"));
	vObj.pmGetTransferPrice();
	ValueToFormAttribute(vObj,"Object");
	ServicesOnChangeAtServer();
	PriceInService();
EndProcedure // ClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
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
	
	Query.SetParameter("ObjectType", Documents.Order.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = Object.Hotel.Language;
	If ValueIsFilled(Object.Client) And ValueIsFilled(Object.Client.Language) Then
		vLang = Object.Client.Language;
	EndIf;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or Not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print"+SelectionRecords.Language, "FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = SelectionDetailRecords.Ref;
			vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print"+vID);
			vCommand.Action = "PrintButtonClick";
			If SelectionDetailRecords.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title,CommandName",
			TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckExternalSystem()
	If ValueIsFilled(Object.Type) Then
		vIntegrationTypes = New Array;
		vIntegrationTypes.Add(Enums.Integrations.Sanatorium);
		
		vQ = New Query;
		vQ.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	NOT ExternalSystemInteractions.DeletionMark
		|	AND NOT ExternalSystemInteractions.IsFolder
		|	AND ExternalSystemInteractions.IsActive
		|	AND ExternalSystemInteractions.IntegrationType IN(&qIntegrationTypes)
		|	AND ExternalSystemInteractions.OrderType = &qOrderType
		|	AND ExternalSystemInteractions.Hotel = &qHotel";
		vQ.SetParameter("qHotel", Object.Hotel);
		vQ.SetParameter("qOrderType", Object.Type);
		vQ.SetParameter("qIntegrationTypes", vIntegrationTypes);
		
		vResult = vQ.Execute().Unload();
		
		If vResult.Count() > 0 Then
			ExternalSystem = vResult[0].Ref;
		Else
			ExternalSystem = Catalogs.ExternalSystemInteractions.EmptyRef();
		EndIf;  
	Else
		ExternalSystem = Catalogs.ExternalSystemInteractions.EmptyRef();
	EndIf;
	
	If ValueIsFilled(ExternalSystem) Then
		Items.FormGetUnpaidMedicalServices.Visible = True;
	Else
		Items.FormGetUnpaidMedicalServices.Visible = False;
	EndIf;
EndProcedure // CheckExternalSystem

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeEnabledGetUnallocatedMedicalServices()
	Items.FormGetUnpaidMedicalServices.Enabled = True;	
	If Items.FormGetUnpaidMedicalServices.Visible Then
		vStatus = Object.Status;
		If ValueIsFilled(vStatus) And (vStatus.IsPaid Or vStatus.isOrderComplete Or vStatus.isOrderCancel) Then
			Items.FormGetUnpaidMedicalServices.Enabled = False;			
		EndIf;
	EndIf;
EndProcedure // ChangeEnabledGetUnallocatedMedicalServices

// -----------------------------------------------------------------------------
&AtServer
Procedure GetUnallocatedMedicalServicesAtServer()
	Try
		vDP = ExternalSystem.DataProcessor;
		If Not ValueIsFilled(vDP) Then
			Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
		EndIf;	
		
		vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
		If vDPO = Undefined Then
			Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
		EndIf;
		
		vMessage = "";
		If Not vDPO.FillUnallocatedAccurals(Object, vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;	
	Except         
		vErrorInfo = ErrorInfo();
	 	tcCommonFunctionOnClientServer.TextMessage(BriefErrorDescription(vErrorInfo));
	EndTry;                     
EndProcedure // GetUnallocatedMedicalServicesAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckOrderTime(pParentDoc, pDate)
	vCheck = True;
	vCheckDate = BegOfDay(pDate);	
	If TypeOf(pParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pParentDoc) = Type("DocumentRef.Reservation") Then
		If BegOfDay(pParentDoc.CheckInDate) > vCheckDate Or vCheckDate > EndOfDay(pParentDoc.CheckOutDate) Then
		   vCheck = False;
		EndIf; 	
	EndIf;
	
	Return vCheck;
EndFunction // CheckOrderTime()      

// -----------------------------------------------------------------------------
&AtClient
Procedure ContinueAfterCheckOrderTime(pResult, pWriteParameters) Export 
	If pResult = DialogReturnCode.Yes Then
		DoNotCheckOrderTime = True;
		Write(pWriteParameters);	   
		Close();
	EndIf;
EndProcedure // ContinueAfterCheckOrderTime()   

#EndRegion
