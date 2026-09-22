
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUUID			 - String						 - InfoBase user uuid
//  pPermissionGroup - CatalogRef.PermissionGroups	 - ref
// 
// Returns:
//  Boolean - true or false
//
Function ChangeUserRoles(pUUID, pPermissionGroup) Export    
	vIsChangedRoles = False;
	If ValueIsFilled(pUUID) And ValueIsFilled(pPermissionGroup) Then
		If pPermissionGroup.InfobaseUserRoles.Count() > 0 Then
			Try
				vUUID = New UUID(pUUID);
			Except
				vUUID = Undefined;
			EndTry;
			If ValueIsFilled(vUUID) Then
				vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
				If vInfoBaseUser <> Undefined Then
					If vInfoBaseUser.UUID = InfoBaseUsers.CurrentUser().UUID Then
						vIsAdministrator = False;
						For Each vRole In vInfoBaseUser.Roles Do
							If vRole = Metadata.Roles.Administrator Then
								vIsAdministrator = True;
							EndIf;
						EndDo;
						If vIsAdministrator Then  
							vStillAdministrator = False;
							For Each vRole In pPermissionGroup.InfobaseUserRoles Do
								vRole = Metadata.Roles.Find(vRole.Role);
								If vRole = Metadata.Roles.Administrator Then
									vStillAdministrator = True;
									Break;
								EndIf;	
							EndDo;
							If Not vStillAdministrator Then    
								vMsg = NStr("en = 'It is impossible to remove system administration permission from yourself!'; 
											|de = 'Es ist unmöglich, die systemadministrationsberechtigung von sich selbst zu entfernen!'; 
											|ru = 'Нельзя удалить права системного администратора у самого себя!'");
								tcCommonFunctionOnClientServer.TextMessage(vMsg);   
								Return False;
							EndIf;
						EndIf;
					EndIf;      
					vInfoBaseUser.Roles.Clear();
					For Each vRole In pPermissionGroup.InfobaseUserRoles Do
						vRole = Metadata.Roles.Find(vRole.Role);
						If vRole <> Undefined Then
							vInfoBaseUser.Roles.Add(vRole);
							vInfoBaseUser.ShowInList = True;
						EndIf;	
					EndDo;
					vInfoBaseUser.Write();  
					vIsChangedRoles = True;
				EndIf;
			EndIf;
		Else
			vIsChangedRoles = True;
		EndIf;
	EndIf;
	Return vIsChangedRoles;
EndFunction // ChangeUserRoles

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUUID			 - UUID							 - UUID
//  pPermissionGroup - CatalogRef.PermissionGroups	 - ref
//  pLastName		 - String						 - LastName
//  pFirstName		 - String						 - FirstName
//  pSecondName		 - String						 - SecondName
//  pDescription	 - String						 - Full name
// 
// Returns:
//  String - User UUID
//
Function CreateInfoBaseUser(pUUID = Undefined, pPermissionGroup, pLastName, pFirstName = "", pSecondName = "", pDescription) Export
	vErrorText = "";
	
	vInfoBaseUser = Undefined;
	If ValueIsFilled(pUUID) Then
		Try
			vUUID = New UUID(pUUID);
		Except
			vUUID = Undefined;
		EndTry;
		If ValueIsFilled(vUUID) Then
			vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
			If vInfoBaseUser <> Undefined Then
				Return String(vUUID);
			EndIf;
		EndIf;
	EndIf;

	vInfoBaseUser = InfoBaseUsers.CreateUser();
	vInfoBaseUser.Name = pDescription;
	If IsBlankString(vInfoBaseUser.Name) Then
		vInfoBaseUser.Name = TrimAll(pLastName + " " + pFirstName);
	EndIf;
	vInfoBaseUser.FullName = TrimAll(pLastName + " " + pFirstName + " " + pSecondName);
	For Each vRole In pPermissionGroup.InfobaseUserRoles Do
		vRole = Metadata.Roles.Find(vRole.Role);
		If vRole <> Undefined Then
			vInfoBaseUser.Roles.Add(vRole);
		EndIf;	
	EndDo;
	vInfoBaseUser.DefaultInterface = Metadata.Interfaces.Reception; 
	vInfoBaseUser.RunMode = ClientRunMode.ManagedApplication;
	If SessionParameters.CurrentLanguage = Catalogs.Languages.RU Then
		vInfoBaseUser.Language = Metadata.Languages.Russian;
	ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.DE Then
		vInfoBaseUser.Language = Metadata.Languages.German;
	Else
		vInfoBaseUser.Language = Metadata.Languages.English;
	EndIf;
	Try
		vInfoBaseUser.Write();
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		vInfoBaseUser = InfoBaseUsers.FindByName(pDescription);
	EndTry;
	
	If vInfoBaseUser <> Undefined Then
		Return TrimAll(vInfoBaseUser.UUID);
	Else
		Raise ?(IsBlankString(vErrorText), NStr("en = 'Failed to create user!'; de = 'Der Benutzer konnte nicht erstellt werden!'; ru = 'Не удалось создать пользователя!'"), vErrorText);
	EndIf;
EndFunction // CreateInfoBaseUser

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUUID	 - UUID	 - UUID
// 
// Returns:
//  Boolean - true or false
//
Function DeleteInfoBaseUser(pUUID) Export
	vResult = True;
	If ValueIsFilled(pUUID) Then
		Try
			vUUID = New UUID(pUUID);
		Except
			vUUID = Undefined;
		EndTry;
		If ValueIsFilled(vUUID) Then
			If InfoBaseUsers.CurrentUser().UUID = vUUID Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You can not delete your user!'; de = 'Sie können Ihren Benutzer nicht löschen!'; ru = 'Нельзя удалить своего пользователя!'"));
				vResult = False;
			Else					
				vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
				If vInfoBaseUser <> Undefined Then
					vInfoBaseUser.Delete();
					vResult = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // DeleteInfoBaseUser

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUUID	 - UUID	 - UUID
// 
// Returns:
//  Boolean - true or false
//
Function DisableInfoBaseUser(pUUID) Export
	vResult = True;
	If ValueIsFilled(pUUID) Then
		Try
			vUUID = New UUID(pUUID);
		Except
			vUUID = Undefined;
		EndTry;
		If ValueIsFilled(vUUID) Then
			If InfoBaseUsers.CurrentUser().UUID = vUUID Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You can not disable your own user!'; de = 'Sie können Ihren Benutzer nicht deaktivieren!'; ru = 'Нельзя отключить своего пользователя!'"));
				vResult = False;
			Else					
				vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
				If vInfoBaseUser <> Undefined Then
					vInfoBaseUser.ShowInList = False;
					vInfoBaseUser.Roles.Clear();
					vInfoBaseUser.Write();
					vResult = True;
				EndIf;
			EndIf;			
		EndIf;
	EndIf;
	Return vResult;
EndFunction // DisableInfoBaseUser

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	If pSelectedForm = "tcItemForm" Or pFormType = "ObjectForm" Then
		If Not IsInRole("Administrator") Then
			pSelectedForm = "tcEmployeeWithNoAccessForm";
			pStandardProcessing = False;
		EndIf;
	EndIf;
EndProcedure // FormGetProcessing

// -----------------------------------------------------------------------------
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref
//  pLang		 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Employee description
//
Function pmGetEmployeeDescription(pEmployee, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pEmployee.Description);
	Else
		If IsBlankString(pEmployee.DescriptionTranslations) Then
			vDescr = TrimAll(pEmployee.Description);
		Else
			vDescr = TrimAll(cmNStr(pEmployee.DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetEmployeeDescription

// -----------------------------------------------------------------------------
//  Get employee operation pbx codes
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref
//  pOperation	 - CatalogRef.Operations - Ref
// 
// Returns:
//  ValueTable - Operation PBX codes
//
Function pmGetOperationPBXCodes(pEmployee, pOperation) Export
	// Build and run query to get data for the operation
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.EmployeePBXCodes AS EmployeePBXCodes
	|WHERE
	|	EmployeePBXCodes.Employee = &qEmployee
	|	AND EmployeePBXCodes.Operation = &qOperation";
	vQry.SetParameter("qEmployee", pEmployee);
	vQry.SetParameter("qOperation", pOperation);
	vCodes = vQry.Execute().Unload();
	Return vCodes;
EndFunction // pmGetOperationPBXCodes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref 
// 
// Returns:
//  CatalogRef.Clients - Ref
//
Function pmGetClient(pEmployee) Export
	If ValueIsFilled(pEmployee.Client) Then
		Return pEmployee.Client;
	EndIf;
	
	// Client not filled lets find
	vClient = cmGetClientByFullnameAndBirthDate(pEmployee.LastName, pEmployee.FirstName, pEmployee.SecondName, pEmployee.DateOfBirth);
	If Not ValueIsFilled(vClient) Then
		vClient = cmGetClientByFullnameAndPhone(pEmployee.LastName, pEmployee.FirstName, pEmployee.SecondName, pEmployee.Phones);
	EndIf;
	
	If Not ValueIsFilled(vClient) Then
		// Create client
		vClient = CreateClientByEmplouee(pEmployee);
		
		vEmpObj = pEmployee.GetObject(); 
		vEmpObj.Client = vClient;
		vEmpObj.Write();
	EndIf;
	
	Return vClient;
EndFunction

// -----------------------------------------------------------------------------
// Function - Create client by emplouee
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref
// 
// Returns:
//  CatalogRef.Clients - Ref
//
Function CreateClientByEmplouee(pEmployee) Export
	
	vClientObj = Catalogs.Clients.CreateItem();
	vClientObj.pmFillAttributesWithDefaultValues();
	vClientObj.LastName = ?(IsBlankString(pEmployee.LastName), pEmployee.Description, pEmployee.LastName);
	vClientObj.FirstName = pEmployee.FirstName;
	vClientObj.SecondName = pEmployee.SecondName;
	vClientObj.DateOfBirth = pEmployee.DateOfBirth;
	vClientObj.Phone = pEmployee.Phones;
	vClientObj.Sex = pEmployee.Sex;
	vClientObj.Address = pEmployee.Address;
	vClientObj.Write();
	// Create check folio
	vFolio = Documents.Folio.CreateDocument();
	vFolio.pmFillAttributesWithDefaultValues();
	vFolio.Client = vClientObj.Ref;
	vFolio.Write();
	vCR = vClientObj.ChargingRules.Add();
	vCR.ChargingRule = Enums.ChargingRuleTypes.Any;
	vCR.ChargingFolio = vFolio.Ref;
	vClientObj.Write();
	
	vClient = vClientObj.Ref;
    Return vClient;
EndFunction

#EndRegion
