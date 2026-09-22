
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)   
	SelEmployee = Parameters.Employee;   
	vEmptyUUID = New UUID("00000000-0000-0000-0000-000000000000");
	If Parameters.UserUUID = vEmptyUUID Then
		vInfoBaseUser = InfoBaseUsers.CurrentUser(); 
		Parameters.UserUUID = vInfoBaseUser.UUID;
	Else
		vUUID = Parameters.UserUUID; 
		vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
	EndIf;
	For Each vInt In Metadata.Interfaces Do
	    Items.DefaultInterface.ChoiceList.Add(vInt.Name, vInt.Presentation()); 
	EndDo;    
	For Each vInt In ClientRunMode Do
	    Items.RumMode.ChoiceList.Add(vInt, vInt); 
	EndDo;  
	vRunMode = ClientRunMode.ManagedApplication;
	 
	If vInfoBaseUser <> Undefined Then    
		If ValueIsFilled(vInfoBaseUser.RunMode) Then
			vRunMode = Items.RumMode.ChoiceList.FindByValue(vInfoBaseUser.RunMode);	
		Else
			Modified = True;
		EndIf;	
		Name 					= vInfoBaseUser.Name;
		Fullname 				= vInfoBaseUser.FullName;
		UnableToChangePassword 	= vInfoBaseUser.CannotChangePassword;
		ShowInList 				= vInfoBaseUser.ShowInList;
		AnnoyingMessages 		= vInfoBaseUser.UnsafeOperationProtection.UnsafeOperationWarnings;
		OSAuthentication	    = vInfoBaseUser.OSAuthentication;
		OSUser	    			= vInfoBaseUser.OSUser;
		DefaultInterface		= ?(vInfoBaseUser.DefaultInterface = Undefined, Undefined, Items.DefaultInterface.ChoiceList.FindByValue(vInfoBaseUser.DefaultInterface.Name)); 
		RunMode 				= vRunMode;
		StandardAuthentication  = vInfoBaseUser.StandardAuthentication;
		If vInfoBaseUser.Language <> Undefined Then 
			Language			= vInfoBaseUser.Language.Name;
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Could not find the user!'; de = 'Der Benutzer konnte nicht gefunden werden!'; ru = 'Не удалось найти пользователя!'"));
	EndIf;
	
	For Each vLanguage In Metadata.Languages Do
		Items.Language.ChoiceList.Add(vLanguage.Name);
	EndDo;
	If Not IsInRole("Administrator") Then
		Items.Name.ReadOnly = True;
		Items.ShowInList.ReadOnly = True;
		Items.ShowInList.Visible = False;
		Items.UnableToChangePassword.ReadOnly = True;
		Items.UnableToChangePassword.Visible = False;
		Items.AnnoyingMessages.ReadOnly = True;
		Items.AnnoyingMessages.Visible = False;
	EndIf;
	PasswordChanged = False;
	If ValueIsFilled(SelEmployee) Then
		If ValueIsFilled(SelEmployee.EmployeePreferences) Then
			If ValueIsFilled(SelEmployee.EmployeePreferences.ProgramAppearanceStyle) Then 
				ProgramAppearanceStyle = SelEmployee.EmployeePreferences.ProgramAppearanceStyle;
			Else
				ProgramAppearanceStyle = Enums.ProgramAppearanceStyles.Windows;	
			EndIf;
		Else
			ProgramAppearanceStyle = Enums.ProgramAppearanceStyles.Windows;	
		EndIf; 
		NeedChangePassword = SelEmployee.NeedChangePassword;
	Else
		Items.FormOpenEmployeePreferences.Enabled = False;
		Items.ProgramAppearanceStyle.Enabled = False;
	EndIf;
	Items.OSUser.Enabled = OSAuthentication;
	Items.Password.Enabled = StandardAuthentication;
	Items.PasswordConfirm.Enabled = StandardAuthentication;   
	If Parameters.Property("ResetNeedChangePassword") Then
		ResetNeedChangePassword = True;		
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'You need to change your password'; de = 'Sie müssen Ihr Passwort ändern'; ru = 'Необходимо сменить пароль'"));
	EndIf;	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure StandardAuthenticationOnChange(pItem)
	Items.Password.Enabled = StandardAuthentication;
	Items.PasswordConfirm.Enabled = StandardAuthentication;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PasswordOnChange(pItem)
	PasswordChanged = True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PasswordConfirmOnChange(pItem)
	If Password <> PasswordConfirm Then     
		vMsg = NStr("en = 'Passwords do not match!'; de = 'Passwörter stimmen nicht überein!'; ru = 'Пароли не совпадают!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , pItem);
		Items.Password.MarkIncomplete 			= True;
		Items.PasswordConfirm.MarkIncomplete 	= True;
	Else
		Items.Password.MarkIncomplete 			= False;
		Items.PasswordConfirm.MarkIncomplete 	= False;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OSAuthenticationOnChange(pItem)
	Items.OSUser.Enabled = OSAuthentication;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	If Save_AtServer() Then
		Notify("Employees.InfobaseUserSettings.Change", SelEmployee);
		Close();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenEmployeePreferences(pCommand)
	vCurEmpPrefRef = GetEmployeePreferencesRef();
	// Open preferences item form
	If ValueIsFilled(vCurEmpPrefRef) Then
		Notify("Employees.InfobaseUserSettings.Change", SelEmployee);
		OpenForm("Catalog.EmployeePreferences.ObjectForm", 
				 New Structure("Key", vCurEmpPrefRef), 
				 ThisObject, UUID, 
				 , 
				 , 
				 New NotifyDescription("UpdateClientInformation", ThisObject, vCurEmpPrefRef),
				 FormWindowOpeningMode.LockOwnerWindow);
	Else              
		vMsg = NStr("en = 'Personal settings could not be opened'; 
					|de = 'Persönliche Einstellungen konnten nicht geöffnet werden'; 
					|ru = 'Не удалось открыть персональные настройки'");
		ShowMessageBox(, vMsg);
	EndIf;
EndProcedure // OpenEmployeePreferences

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	vResult = False;
	If Password <> PasswordConfirm Then   
		vMsg = NStr("en = 'Passwords do not match!'; de = 'Passwörter stimmen nicht überein!'; ru = 'Пароли не совпадают!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , Items.PasswordConfirm);
		Items.Password.MarkIncomplete 			= True;
		Items.PasswordConfirm.MarkIncomplete 	= True;
	Else
		vInfoBaseUser = InfoBaseUsers.FindByUUID(Parameters.UserUUID);
		If vInfoBaseUser <> Undefined Then
			vInfoBaseUser.Name = Name;
			vInfoBaseUser.FullName = Fullname;
			If PasswordChanged Then
				vInfoBaseUser.Password = Password;
			EndIf;
			vInfoBaseUser.CannotChangePassword = UnableToChangePassword;
			vInfoBaseUser.ShowInList = ShowInList;
			vInfoBaseUser.UnsafeOperationProtection.UnsafeOperationWarnings = AnnoyingMessages;
			If Not IsBlankString(Language) Then
				vInfoBaseUser.Language = Metadata.Languages.Find(Language);
			EndIf;
			vInfoBaseUser.OSAuthentication = OSAuthentication;
			vInfoBaseUser.OSUser = OSUser;
			If IsBlankString(DefaultInterface) Then
				vInfoBaseUser.DefaultInterface = Undefined;
			Else
				vInfoBaseUser.DefaultInterface = Metadata.Interfaces.Find(DefaultInterface);
			EndIf;	
			vInfoBaseUser.StandardAuthentication = StandardAuthentication;    
			vInfoBaseUser.RunMode = GetRunMode(RunMode);
			vInfoBaseUser.Write();
			If ResetNeedChangePassword And PasswordChanged Then
				vNeedChangePassword	= False;
			Else
				vNeedChangePassword = NeedChangePassword;
			EndIf;
			PasswordChanged = False;
			If ValueIsFilled(SelEmployee) Then
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
					vCurEmpPrefObj.ProgramAppearanceStyle = ProgramAppearanceStyle;
					vCurEmpPrefObj.Write();	
				EndIf; 
					
				vSelEmployeeObj = SelEmployee.GetObject();
				vSelEmployeeObj.NeedChangePassword = vNeedChangePassword;
				vSelEmployeeObj.Write();
			EndIf;
			vResult = True;
		Else              
			vMsg = NStr("en = 'Could not find the user to apply the changes!'; 
						|de = 'Der Benutzer zum anwenden der änderungen konnte nicht gefunden werden!'; 
						|ru = 'Не удалось найти пользователя для применения изменений!'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg);
		EndIf;
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function GetEmployeePreferencesRef()
	vCurEmpPrefRef = Catalogs.EmployeePreferences.EmptyRef();
	If ValueIsFilled(SelEmployee) Then
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
			vCurEmpPrefObj.ProgramAppearanceStyle = ProgramAppearanceStyle;
			vCurEmpPrefObj.Write();
		EndIf;	
	EndIf;
	Return vCurEmpPrefRef;
EndFunction // GetEmployeesRefByUUID

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateClientInformation(pData, pExtraParams) Export
	If ValueIsFilled(pExtraParams) Then
		ProgramAppearanceStyle = tcOnServer.cmGetAttributeByRef(pExtraParams, "ProgramAppearanceStyle");	
	EndIf;
EndProcedure // UpdateClientInformation

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetRunMode(pMode)
	vMapModes = New Map;
	vMapModes.Insert("Auto", ClientRunMode.Auto);
	vMapModes.Insert("Авто", ClientRunMode.Auto); 
	vMapModes.Insert("ОбычноеПриложение", ClientRunMode.OrdinaryApplication);
	vMapModes.Insert("OrdinaryApplication", ClientRunMode.OrdinaryApplication);
	vMapModes.Insert("Обычное приложение", ClientRunMode.OrdinaryApplication);
	vMapModes.Insert("ManagedApplication", ClientRunMode.ManagedApplication);
	vMapModes.Insert("Managed application", ClientRunMode.ManagedApplication);
	vMapModes.Insert("УправляемоеПриложение", ClientRunMode.ManagedApplication);
	vMapModes.Insert("Управляемое приложение", ClientRunMode.ManagedApplication);
	Try
		vMode = vMapModes[pMode];  
	Except
		vMode = ClientRunMode.Auto;
	EndTry;	
	Return vMode;
EndFunction

#EndRegion
