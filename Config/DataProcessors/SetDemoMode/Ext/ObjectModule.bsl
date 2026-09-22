
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Any	 - Additional parameters
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	AddPrefixHotel = True;
	Prefix = "TEST_";
	TurnOffDevices = True;
	TurnOffScheduledJob = True;
	SetNewUserStyle = True;
	NewUserStyle = Enums.ProgramAppearanceStyles.Orange;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Any	 - Additional parameters
//  pIsInteractive	 - Boolean	 - is interactive use
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export   
	vRemarks = "AddPrefix: " + AddPrefixHotel + " Prefix " + Chars.LF 
				+ "TurnOffDevices: " + TurnOffDevices + Chars.LF + "TurnOffScheduledJob: " + TurnOffScheduledJob;
	WriteLogEvent("RunDP.SetDemoMode", EventLogLevel.Warning, ThisObject, , vRemarks);
	
	// 1. Rename hotels
	If AddPrefixHotel And Not IsBlankString(Prefix) Then 
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Hotels.Ref AS Ref
		|FROM
		|	Catalog.Hotels AS Hotels
		|WHERE
		|	Hotels.IsFolder = FALSE";
		
		QueryResult = vQuery.Execute();
		
		vHotelList = QueryResult.Select();
		
		While vHotelList.Next() Do
			vHotelObj = vHotelList.Ref.GetObject();
			vHotelObj.Description = Prefix + vHotelObj.Description;
			vHotelObj.Write();
		EndDo;
	EndIf;
	// 2. Turn Off devices
	If TurnOffDevices Then
		// Cash registers
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	CashRegisters.Ref AS Ref
		|FROM
		|	Catalog.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.IsControlledByProgram";
		
		vQueryResult = vQuery.Execute();
		
		vCashRegisterList = vQueryResult.Select();
		
		While vCashRegisterList.Next() Do
			vCashRegisterObj = vCashRegisterList.Ref.GetObject();
			vCashRegisterObj.IsControlledByProgram = False;
			vCashRegisterObj.Write();
		EndDo;
		// 2.1 Turn off all devices for  each workstation
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Workstations.Ref AS Ref
		|FROM
		|	Catalog.Workstations AS Workstations
		|WHERE
		|	Workstations.IsFolder = FALSE";
		
		vQueryResult = vQuery.Execute();
		
		vWSList = vQueryResult.Select();
		
		While vWSList.Next() Do
			vWSObj = vWSList.Ref.GetObject();
			vWSObj.HasConnectionToDoorLockSystem = False;
			vWSObj.HasConnectionToCreditCardsProcessingSystem = False;
			vWSObj.HasConnectionToIdentityCardsProcessingSystem = False;
			vWSObj.HasConnectionToRibbonPrinter = False;
			vWSObj.HasConnectionToBarcodesScanner = False;
			vWSObj.HasConnectionToCashAcceptors = False;
			vWSObj.HasConnectionToImagesScanner = False;
			vWSObj.HasConnectionToWEBCamera = False;  
			vWSObj.HasConnectionToSimpleCalls = False;
			vWSObj.Write();
		EndDo;
	EndIf;
	// 3. Turn off scheduled Job
	If TurnOffScheduledJob Then
		vJobs = ScheduledJobs.GetScheduledJobs(New Structure("Use", True));
		For Each vJob In vJobs Do
			vJob.Use = False;
			vJob.Write();
		EndDo;
	EndIf;	
	// Set user programm apperance
	If SetNewUserStyle And ValueIsFilled(NewUserStyle) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Employees.Ref AS Ref
		|FROM
		|	Catalog.Employees AS Employees
		|WHERE
		|	Employees.IsFolder = FALSE";
		vQueryResult = vQuery.Execute();
		vUserList = vQueryResult.Select();
		While vUserList.Next() Do
			SelEmployee = vUserList.Ref;
			If ValueIsFilled(SelEmployee.EmployeePreferences) Then
				vCurEmpPrefRef = SelEmployee.EmployeePreferences;
			Else
				// Create new one
				vCurEmpPrefObj = Catalogs.EmployeePreferences.CreateItem();
				vCurEmpPrefObj.Description = SelEmployee.Description;
				vCurEmpPrefObj.Write();
				vCurEmpPrefRef = vCurEmpPrefObj.Ref;
				
				vCurEmpObj = SelEmployee.GetObject();
				vCurEmpObj.EmployeePreferences = vCurEmpPrefRef;
				vCurEmpObj.Write();
			EndIf;
			If ValueIsFilled(vCurEmpPrefRef) Then
				vCurEmpPrefObj = vCurEmpPrefRef.GetObject();
				vCurEmpPrefObj.ProgramAppearanceStyle = NewUserStyle;
				vCurEmpPrefObj.Write();	
			EndIf;
		EndDo;
	EndIf;	
	RefreshObjectsNumbering();
EndProcedure // pmRun

#EndRegion
	 