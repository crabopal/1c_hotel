
#Region EventHandlers

// -----------------------------------------------------------------------------
// Set session parameters
// -----------------------------------------------------------------------------
Procedure SessionParametersSetting()
	SessionParameters.UpdateInProgress = False;
	SessionParameters.IsDemoMode = False;
	// Check user first run
	If InfoBaseUsers.GetUsers().Count() = 0 Then
		SessionParameters.CurrentUser = Catalogs.Employees.EmptyRef();
		SessionParameters.CurrentHotel = Catalogs.Hotels.EmptyRef();
		SessionParameters.CurrentWorkstation = Catalogs.Workstations.EmptyRef();
		SessionParameters.SMSDeliveryIsStopped = False;
		SessionParameters.StyleName = "Windows";
		
		// Current language
		Try
			SessionParameters.CurrentLanguage = Catalogs.Languages[CurrentLanguage().LanguageCode];
		Except
			SessionParameters.CurrentLanguage = Catalogs.Languages.EmptyRef();
		EndTry;    
		
		// Configuration name
		SessionParameters.ConfigurationName = "en = '1C:Hotel'; de = '1C:Hotel'; ru = '1С:Отель'";
		SessionParameters.ConfigurationPresentation = NStr(TrimAll(SessionParameters.ConfigurationName));
		
		// APDEX
		SessionParameters.APDEXRemarks = APDEXPerformanceSystemOnServer.GetAPDEXRemarks();
		
		Return;
	EndIf;
	
	// Get current user
	vCurUser = InfoBaseUsers.CurrentUser();
	vCurUserUUID = TrimAll(vCurUser.UUID);
	vCurEmployee = Undefined;
	
	// Database UUID initialization
	vInfoBaseUUID = TrimAll(Constants.InfoBaseUUID.Get());
	If IsBlankString(vInfoBaseUUID) Then
		vInfoBaseUUID = String(New UUID);
		Constants.InfoBaseUUID.Set(vInfoBaseUUID);
		// Check all employees and move user UUID from employee code to the special information register
		CheckAndCorrectUsersUUID(vCurEmployee, vCurUserUUID);
	EndIf;
	
	// SMS delivery management initialization
	SessionParameters.SMSDeliveryIsStopped = False;
	
	// Get current user
	If Not ValueIsFilled(vCurEmployee) Then
		vCurEmployee = cmGetEmployeeByUserUUID(vCurUser.UUID);
	EndIf;
	
	// If this is a new employee, then create it in the database
	If Not ValueIsFilled(vCurEmployee) Then
		vCurEmployee = CreateEmployee(vCurUser);
		
		WriteLogEvent(NStr("en = 'System.OnStart'; de = 'System.OnStart'; ru = 'Программа.Запуск'"), EventLogLevel.Information, vCurEmployee.Metadata(), vCurEmployee);
		
		// Set session parameters
		SessionParameters.CurrentUser = vCurEmployee;
		SessionParameters.CurrentHotel = vCurEmployee.Hotel;
		
		// Save user UUID to the infobase users register
		SaveUserUUID(vCurEmployee, vCurUser);
		vUserUUIDs = cmGetUserUUIDsByEmployee(vCurEmployee);
		
		// Update user permissions
		For Each vUserUUIDsRow In vUserUUIDs Do
			If Not IsBlankString(vUserUUIDsRow.UserUUID) Then
				Catalogs.Employees.ChangeUserRoles(TrimAll(vUserUUIDsRow.UserUUID), vCurEmployee.PermissionGroup); 
			EndIf;
		EndDo;
	Else
		// Assume that user login is disabled if employee is marked for deletion 
		If vCurEmployee.DeletionMark Then
			Raise NStr("en = 'Employee is marked for deletion!'; de = 'Employee is marked for deletion!'; ru = 'Сотрудник помечен на удаление!'");
		EndIf;
		
		// Update user name
		UpdateUserName(vCurEmployee, vCurUser);

		// Set session parameters
		SessionParameters.CurrentUser = vCurEmployee;
		SessionParameters.CurrentHotel = vCurEmployee.Hotel;
	EndIf;
	
	// Current workstation  
	vCurComputer = GetWorkstation(vCurEmployee);
	SessionParameters.CurrentWorkstation = vCurComputer;
	
	// Current time zone
	tcOnServer.SetTimeZone(vCurComputer);
	
	// Current style
	If ValueIsFilled(vCurEmployee.EmployeePreferences) Then
		vStyle = vCurEmployee.EmployeePreferences.ProgramAppearanceStyle;
		If ValueIsFilled(vStyle) Then
			SessionParameters.StyleName = vStyle.Metadata().EnumValues[Enums.ProgramAppearanceStyles.IndexOf(vStyle)].Name;
			Try
				// Supported only in platform versions started from 8.3.13
				Execute("MainStyle = StyleLib[SessionParameters.StyleName]");
			Except
			EndTry;
		Else
			SessionParameters.StyleName = "Windows";
		EndIf;
	Else
		SessionParameters.StyleName = "Windows";
	EndIf;
	
	// Current language
	Try
		SessionParameters.CurrentLanguage = Catalogs.Languages[CurrentLanguage().LanguageCode];
	Except
		SessionParameters.CurrentLanguage = Catalogs.Languages.EmptyRef();
	EndTry;    
	
	// Configuration name
	SessionParameters.ConfigurationName = "en = '1C:Hotel'; de = '1C:Hotel'; ru = '1С:Отель'";
	SessionParameters.ConfigurationPresentation = NStr(TrimAll(SessionParameters.ConfigurationName));
	
	// APDEX
	SessionParameters.APDEXRemarks = APDEXPerformanceSystemOnServer.GetAPDEXRemarks();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CreateEmployee(pCurUser)
	vNewEmployeeCode = cmGetEmployeeCode(pCurUser.FullName);
	For i = 0 To 99 Do
		If Not ValueIsFilled(Catalogs.Employees.FindByCode(vNewEmployeeCode, False)) Then
			Break;
		Else
			i = i + 1;
			vNewEmployeeCode = vNewEmployeeCode + Format(i, "NFD=0; NG=");
		EndIf;
	EndDo;
	// Get employee names and sex from the full name
	vLastName = "";
	vFirstName = "";
	vSecondName = "";
	vSex = Undefined;
	cmParseClientFullName(pCurUser.FullName, vLastName, vFirstName, vSecondName, vSex);
	// Create item in the Employees catalog
	vNewEmployeeObj = Catalogs.Employees.CreateItem();
	vNewEmployeeObj.Hotel = Catalogs.Hotels.FindByCode("001");
	vNewEmployeeObj.PermissionGroup = GetAdministartorPermissionGroup();
	vNewEmployeeObj.Code = vNewEmployeeCode;
	vNewEmployeeObj.Description = pCurUser.Name;
	vNewEmployeeObj.LastName = vLastName;
	vNewEmployeeObj.FirstName = vFirstName;
	vNewEmployeeObj.SecondName = vSecondName;
	vNewEmployeeObj.Sex = vSex;
	vNewEmployeeObj.AllowAccessToSystem = True; 
	If Not pCurUser.PasswordIsSet Then
		vNewEmployeeObj.NeedChangePassword = True;	
	EndIf;
	vNewEmployeeObj.Write();

	vCurEmployee = vNewEmployeeObj.Ref;
	Return vCurEmployee;
EndFunction // CreateEmployee

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.PermissionGroups - Administrator permisson group or empty referense if no any
//
Function GetAdministartorPermissionGroup()
	vPermissionGroup = Catalogs.PermissionGroups.EmptyRef();
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	PermissionGroupsInfobaseUserRoles.Ref AS Ref
		|FROM
		|	Catalog.PermissionGroups.InfobaseUserRoles AS PermissionGroupsInfobaseUserRoles
		|WHERE
		|	PermissionGroupsInfobaseUserRoles.Role = &qRole
		|
		|GROUP BY
		|	PermissionGroupsInfobaseUserRoles.Ref";
	
	vQuery.SetParameter("qRole", Metadata.Roles.Administrator.Name);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vPermissionGroup = vSelectionDetailRecords.Ref;
	EndDo;
	
	Return vPermissionGroup;
EndFunction // GetAdministartorPermissionGroup

// --------------------------------------------------------------------------------
Procedure UpdateUserName(pCurEmployee, pCurUser)
	vUsers = InformationRegisters.InfoBaseUsers.CreateRecordManager();
	vUsers.Employee = pCurEmployee;
	vUsers.UserUUID = TrimAll(pCurUser.UUID);
	vUsers.Read();
	If vUsers.Selected() Then
		If TrimR(vUsers.UserName) <> TrimR(pCurUser.Name) Then
			vUsers.Employee = pCurEmployee;
			vUsers.UserUUID = TrimAll(pCurUser.UUID);
			vUsers.UserName = TrimR(pCurUser.Name);
			vUsers.Write(True);
		EndIf;
	Else
		vUsers.Employee = pCurEmployee;
		vUsers.UserUUID = TrimAll(pCurUser.UUID);
		vUsers.UserName = TrimR(pCurUser.Name);
		vUsers.Write(True);
	EndIf;  
	If Not pCurUser.PasswordIsSet And Not pCurEmployee.NeedChangePassword Then  
		vNewEmployeeObj = pCurEmployee.GetObject();
		vNewEmployeeObj.NeedChangePassword = True;
		vNewEmployeeObj.Write();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure CheckAndCorrectUsersUUID(pCurEmployee, pCurUserUUID)
	vUsers = InformationRegisters.InfoBaseUsers.CreateRecordManager();
	vEmployees = cmGetAllEmployees(Undefined, True);
	For Each vEmployeesRow In vEmployees Do
		vEmployee = vEmployeesRow.Employee;
		If StrLen(TrimAll(vEmployee.Code)) = 36 Then
			If TrimAll(vEmployee.Code) = pCurUserUUID Then
				pCurEmployee = vEmployee;
			EndIf;
			// Write record to infobase users
			vUsers.Employee = vEmployee;
			vUsers.UserUUID = TrimAll(vEmployee.Code);
			vUsers.UserName = TrimAll(vEmployee.Description);
			vUsers.Write(True);
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure SaveUserUUID(pCurEmployee, pCurUser)
	vUsers = InformationRegisters.InfoBaseUsers.CreateRecordManager();
	vUsers.Employee = pCurEmployee;
	vUsers.UserUUID = TrimAll(pCurUser.UUID);
	vUsers.UserName = TrimR(pCurUser.Name);
	vUsers.Write(True);
EndProcedure

// --------------------------------------------------------------------------------
Function GetWorkstation(pCurEmployee)
	vCurComputerName = ComputerName();
	vCurComputer = tcOnServer.FindWorkstationByName(vCurComputerName);
	If Not ValueIsFilled(vCurComputer) Then
		vCurComputer = tcOnServer.AddWorkstation(vCurComputerName, pCurEmployee);
	EndIf;
	If ValueIsFilled(pCurEmployee) Then
		If ValueIsFilled(pCurEmployee.Workstation) Then
			vCurComputer = pCurEmployee.Workstation;
		EndIf;
	EndIf;
	Return vCurComputer;
EndFunction

#EndRegion
