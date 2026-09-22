
#Region Public

// -----------------------------------------------------------------------------
//  Function checks if conversion routines are have to be processed
//  due to change in the program version number
// 
// Returns:
//  Boolean - True if no conversion was processed or database conversion
//  routines processed successfully, False if error occurred during
//  conversion
//
Function cmCheckInfoBaseVersion() Export
	vIsFirstRun = IsBlankString(Constants.ProgramVersionNumber.Get());
	If vIsFirstRun Then
		DoMessageBox(NStr("en = 'This is program first run! Program should be restarted with system administrator rights and interface.'; 
						  |de = 'Der erste Start des Programms wurde erkannt! Das Programm muss mit der Schnittstelle und den Rechten des Systemadministrators ausgeführt werden.'; 
						  |ru = 'Обнаружен первый запуск программы! Программу нужно запустить с интерфейсом и правами системного администратора.'"), 10);
		Return False;
	ElsIf TrimAll(Constants.ProgramVersionNumber.Get()) <> TrimAll(Metadata.Version) Then
		DoMessageBox(NStr("en = 'Program version number has changed! Program should be restarted with system administrator rights and interface.'; 
						  |de = 'Die Konfigurationsrelease-Nummer hat sich geändert! Das Programm muss mit der Schnittstelle und den Rechten des Systemadministrators ausgeführt werden.'; 
						  |ru = 'Изменился номер релиза конфигурации! Программу нужно запустить с интерфейсом и правами системного администратора.'"), 10);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // cmCheckInfoBaseVersion
	
// -----------------------------------------------------------------------------
//  Function checks if conversion routines are have to be processed
//  due to change in the program version number
//
// Parameters:
//  pFrmWithChanges	 - Form	 - Frm with changes
// 
// Returns:
//  Boolean - True if no conversion was processed or database conversion
//  routines processed successfully, False if error occurred during
//  conversion
//  -----------------------------------------------------------------------------
//
Function cmDoInfoBaseUpdate(pFrmWithChanges = Undefined) Export
	vIsFirstRun = IsBlankString(Constants.ProgramVersionNumber.Get());
	If Not vIsFirstRun And TrimAll(Constants.ProgramVersionNumber.Get()) <> TrimAll(Metadata.Version) Then
		DoMessageBox(NStr("en = 'Program version number has changed. Info base update will be done.'; 
						  |de = 'Die Konfigurationsrelease-Nummer hat sich geändert. Es erfolgt eine Aktualisierung der Informationsbasis.'; 
						  |ru = 'Изменился номер релиза конфигурации. Будет выполнено обновление информационной базы.'"), 5);

		vFrm = DataProcessors.InfoBaseUpdate.GetForm();
		vResult = vFrm.DoModal();
		If vResult <> True Then
			Return False;
		EndIf; 
	Else
		// Set current version   
		tcInfobaseUpdate.cmUpdateInfobaseVersion();
		Return True;
	EndIf;

	// Check user rights for info base update
	If Not IsInRole("Administrator") Then 
		DoMessageBox(NStr("en = 'You do not have enough rights to do info base update! Program will be closed.'; 
						  |de = 'Nicht ausreichend Rechte für die Durchführung einer Aktualisierung! Das Programm wird geschlossen.'; 
						  |ru = 'Недостаточно прав для выполнения обновления! Работа программы будет завершена.'"), 5);
		Return False;
	EndIf;  
	If Not tcInfobaseUpdate.IsRelevantVersionWithoutAssembly() Then  
		
		vForm = "DataProcessor.InfoBaseUpdate.Form.tcErrorForm";
		
		// Show message
		vMsg = NStr("en = 'The infobase is being updated!'; de = 'Die Informationsbasis wird aktualisiert!'; ru = 'Выполняется обновление информационной базы!'");
		vParams = New Structure("MessageText, DoProcessing", vMsg, True);
		OpenForm(vForm, vParams);
		
		// Do info base update
		If Not DataProcessors.InfoBaseUpdate.Create().pmDoInfobaseUpdate(pFrmWithChanges) Then
			DoMessageBox(NStr("en = 'Errors were found while updating info base! Check system log.'; 
							  |de = 'Fehler bei der Aktualisierung der Informationsbasis! Prüfen Sie die Protokolldatei.'; 
							  |ru = 'В процессе обновления информационной базы были ошибки! Проверьте журнал регистрации.'"), 5);
		EndIf; 
		// Close message window
		Notify("InfoBaseUpdate.Done");
	Else
		// Set current version
		tcInfobaseUpdate.cmUpdateInfobaseVersion();	
	EndIf;
	// Check info base update status
	If TrimAll(Constants.ProgramVersionNumber.Get()) <> TrimAll(Metadata.Version) Then
		vMessage = NStr("en = 'Info base update was not done! Continue to run?'; 
						|de = 'Die Aktualisierung der Informationsbasis wurde nicht durchgeführt! Die Arbeit des Programms fortsetzen?'; 
						|ru = 'Не выполнено обновление информационной базы! Продолжить работу программы?'");
		vReply = DoQueryBox(vMessage, QuestionDialogMode.YesNo, 20, DialogReturnCode.Yes);
		Return (vReply = DialogReturnCode.Yes);
	EndIf;

	Return True;
EndFunction // cmDoInfoBaseUpdate

// -----------------------------------------------------------------------------
//  Function shows program license agreement
// 
// Returns:
//  Boolean - False if user declined the agreement, True otherwise
//
Function cmShowLicenseAgreement() Export
	vIsFirstRun = IsBlankString(Constants.ProgramVersionNumber.Get());
	If vIsFirstRun Then
		vLicenseAgreement = DataProcessors.LicenseAgreement.Create();
		vUserChoice = vLicenseAgreement.GetForm().DoModal();
		If vUserChoice = False Or vUserChoice = Undefined Then
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmShowLicenseAgreement

// -----------------------------------------------------------------------------
//  Procedure is used to run team viewer application to allow
//  help line employees to switch to the client computer
//
Procedure cmRunSupportConnection() Export
	OpenForm("CommonForm.tcSupportForm");
EndProcedure // cmRunSupportConnection

// -----------------------------------------------------------------------------
//  Procedure is used to install Exontrol G2antt ActiveX control
Procedure cmCheckG2anttControl() Export 
	// ACC:561-off
	vDir = cmCommonDir();
	vG2anttFileName = vDir + "ExG2antt.dll";
	Try
		vFile = New File(vG2anttFileName);
		If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
			GetCommonTemplate("ExG2antt").Write(vG2anttFileName);
			// Check that component was copied successfully
			vFile = New File(vG2anttFileName);
			If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
				Status(NStr("en = 'Gantt ActiveX control component copied OK!'; 
							|de = 'Die ActiveX-Komponente des Zimmerbestandes wurde erfolgreich kopiert!'; 
							|ru = 'ActiveX компонента карты номероного фонда скопирована успешно!'"));
				// Try to register component
				System("regsvr32 /s " + """" + vG2anttFileName + """", vDir);
			EndIf;
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		tcCommonFunctionOnClientServer.UserMessage(vErrorDescription);
		vErrorText = NStr("en = 'The program has to install additional components to show rooms gantt chart! 
                           |Right-click on the shortcut launch 1C: Enterprise and select <Run as Administrator>.
                           |
                           |You can proceed to work with current session normally but please do not open rooms gantt chart.'; de = 'Um die Karte der Zimmerauslastung anzuzeigen, muss das Programm zusätzliche Komponenten installieren!
                           |Rechtsklick auf die Verknüpfung launch 1C: Enterprise und wählen Sie <als Administrator Ausführen>.
                           |
                           |Sie können die Arbeit mit dem Programm wie gewohnt in dieser Sitzung fortsetzen, jedoch wird die graphische Karte des Zimmerbestandes nicht angezeigt.'; ru = 'Для того чтобы отобразить карту загрузки номеров программа должна установить дополнительные компоненты! 
                           |Необходимо целкнуть правой кнопкой мыши по ярлыку запуска 1С:Предприятие и выбрать пункт <Запуск от имени Администратора>.
                           |
                           |Вы можете продолжить работу с программой в этой сессии как обычно, однако форма графической карты номерного фонда показываться не будет.'");
		DoMessageBox(vErrorText);
	EndTry;     
	// ACC:561-on
EndProcedure // cmCheckG2anttControl

// -----------------------------------------------------------------------------
//  Description: The procedure shows the description of changes
Procedure cmShowDescriptionUpdate() Export
	vFrm = DataProcessors.InfoBaseUpdate.GetForm("DescriptionUpdate");
	vTemplate = DataProcessors.InfoBaseUpdate.GetTemplate("DescriptionUpdate");
	vList = New ValueList;
	For Each vInt In vTemplate.Areas Do
		If Left(vInt.Name, 7) = "Version" Then
			vList.Add(Right(vInt.Name, 6));	
		EndIf;
	EndDo;
	vList.SortByValue(SortDirection.Desc);
	vSpreadsheetDocument = New  SpreadsheetDocument;
	IsFirst = True;
	For Each vInt In vList Do
		vVersion = vInt.Value;
		If IsFirst Then
			Try
				vSpreadsheetDocument.Put(vTemplate.GetArea("Head" + vVersion));
				vSpreadsheetDocument.Put(vTemplate.GetArea("Version" + vVersion));
				vSpreadsheetDocument.Put(vTemplate.GetArea("Indent"));
			Except
			EndTry;
			IsFirst = False;
		Else
			Try
				vSpreadsheetDocument.Put(vTemplate.GetArea("Head" + vVersion));
				vSpreadsheetDocument.StartRowGroup("Version" + vVersion, False);
				vSpreadsheetDocument.Put(vTemplate.GetArea("Version" + vVersion));
				vSpreadsheetDocument.EndRowGroup();
				vSpreadsheetDocument.Put(vTemplate.GetArea("Indent"));
			Except
			EndTry;
		EndIf;
	EndDo;
	vFrm.TemplateDescriptionUpdate = vSpreadsheetDocument;
	vFrm.Open();
EndProcedure // cmShowDescriptionUpdate

// -----------------------------------------------------------------------------
//  The function checks the version of the platform
//
// Parameters:
//  pMinVersion	 - String	 - MinVersion
// 
// Returns:
//  Boolean - False if it not allowed to use the program, otherwise the True
//
Function cmCheckPlatformVersion(pMinVersion = "") Export
	If IsBlankString(pMinVersion) Then
		pMinVersion = "8.3.12.1469";
	EndIf;
	
	vInfo 			= New SystemInfo;
	vCurrVersion 	= vInfo.AppVersion;
	
	vMinVersionArr 	= StrSplit(pMinVersion, ".");
	vCurrVerArr 	= StrSplit(vCurrVersion, ".");
	
	vRes = 0;
	
	For vInd = 0 To 3 Do
		vRes = Number(vCurrVerArr[vInd]) - Number(vMinVersionArr[vInd]);
		If vRes < 0 Then
			Return False;
		EndIf;
		If vRes > 0 Then
			Return True;
		EndIf;
	EndDo;
	Return True;
EndFunction // cmCheckPlatformVersion

// -----------------------------------------------------------------------------
//  Description: The function checks the type of the platform
// 
// Returns:
//  PlatformType - PlatformType
//
Function cmGetPlatformType() Export
	vInfo = New SystemInfo;
	Return	vInfo.PlatformType;
EndFunction // cmGetPlatformType

#EndRegion
