
#Region FormEventHandlers

// -----------------------------------------------------------------------------
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	
	Hotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Hotel) Then
		Company = Hotel.Company;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	// Fill cash registers
	FillListOfCashRegisters();
	
	CurrentShift = True;
	
	// Fill list of payment methods 
	FillListOfPaymentMethods();

	SetParmetersDinamicList();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegistersOnChange(Item)
	SetParmetersDinamicList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UserPaymentMethodOnChange(Item)
	SetParmetersDinamicList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrentShiftOnChange(Item)
	SetParmetersDinamicList();
	If CurrentShift Then
		Title = Nstr("en = 'Deferred payments'; de = 'Zahlungsaufschub'; ru = 'Отложенные чеки'");
	Else
		Title = Nstr("en = 'Payments'; de = 'Zahlungen'; ru = 'Платежи'");
	EndIf;	
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(Company);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(Company, SessionParameters.CurrentWorkstation);
	EndIf;
	If vCashRegistersList.Count() > 0 Then
		CashRegister = vCashRegistersList[0].Value;
	EndIf;	
	// Attach list of cash registers to the form item
	Items.CashRegisters.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vPaymentList = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , CashRegister).UnloadValues();
	Items.UserPaymentMethod.ListChoiceMode = vPaymentList.Count() > 0;
	Items.UserPaymentMethod.ChoiceList.LoadValues(vPaymentList);
EndProcedure // FillListOfPaymentMethods()
// -----------------------------------------------------------------------------
&AtServer
Procedure SetParmetersDinamicList()
	List.Parameters.SetParameterValue("qCashRegister", CashRegister);
	List.Parameters.SetParameterValue("qPaymentMethod", PaymentMethod);
	List.Parameters.SetParameterValue("qCurrentShift", CurrentShift);
	List.Parameters.SetParameterValue("qDateFrom", CalculateDateFrom(CashRegister));
	List.Parameters.SetParameterValue("qDateTo", CurrentDate());
	List.Parameters.SetParameterValue("qHotel", Hotel);

EndProcedure // SetParmetersDinamicList()

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateDateFrom(pCashRegister) Export
	vDateFrom = CurrentDate();
	// Try to find previous close of cash register day
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CloseOfCashRegisterDay.Date AS DateTo,
	|	CloseOfCashRegisterDay.Ref AS CloseOfCashRegisterDay,
	|	CloseOfCashRegisterDay.DateFrom AS DateFrom
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.Date < &qDateTo
	|	AND CloseOfCashRegisterDay.Posted = TRUE
	|
	|ORDER BY
	|	DateTo DESC";
	vQry.SetParameter("qCashRegister", pCashRegister);
	vQry.SetParameter("qDateTo", vDateFrom);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDateFrom = vDocsRow.DateTo;
		Break;
	EndDo;
	Return vDateFrom;
EndFunction // pmCalculateDateFrom

#EndRegion
