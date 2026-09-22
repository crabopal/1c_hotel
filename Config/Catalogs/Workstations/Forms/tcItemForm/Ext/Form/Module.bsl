
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// Fill TimeZone List
	vZonesArray = GetAvailableTimeZones();
	For Each vTimeZone In vZonesArray Do
		vTimeZonePresentation = TimeZonePresentation(vTimeZone);
		Items.WorkstationTimeZone.ChoiceList.Add(TrimAll(vTimeZone), TrimAll(vTimeZone) + ?(IsBlankString(vTimeZonePresentation), "", " - " + vTimeZonePresentation));
	EndDo;
	
	//Fill connected devices
	vQuery = New Query;
	vQuery.Text = "SELECT
	              |	ConnectedDevices.Workstation AS Workstation,
	              |	ConnectedDevices.DeviceType AS DeviceType,
	              |	ConnectedDevices.DeviceSettings AS DeviceSettings,
	              |	ConnectedDevices.IsActive AS IsActive
	              |FROM
	              |	InformationRegister.ConnectedDevices AS ConnectedDevices
	              |WHERE
	              |	ConnectedDevices.Workstation = &CurrentWorkstation
	              |
	              |ORDER BY
	              |	DeviceType,
	              |	DeviceSettings";
	
	vQuery.SetParameter("CurrentWorkstation", Object.Ref);
	vResult = vQuery.Execute().Select();
	
	ConnectedCreditCardProcessingSystems = 0;
	ConnectedDoorLockSystems = 0;
	
	While vResult.Next() Do
		vNewRow = AllConnectedDevices.Add();
		vNewRow.Workstation = vResult.Workstation;
		vNewRow.DeviceType = vResult.DeviceType;
		vNewRow.DeviceSettings = vResult.DeviceSettings;
		vNewRow.IsActive = vResult.IsActive;
		If vResult.DeviceType = Enums.DeviceTypes.CreditCardsProcessingSystemParameters Then
			ConnectedCreditCardProcessingSystems = ConnectedCreditCardProcessingSystems + 1;
		ElsIf vResult.DeviceType = Enums.DeviceTypes.DoorLockSystemParameters Then
			ConnectedDoorLockSystems = ConnectedDoorLockSystems + 1;
		EndIf;
	EndDo;
	
	Items.ConnectedCreditCardProcessingSystem.RowFilter = New FixedStructure("Workstation, DeviceType", Object.Ref, Enums.DeviceTypes.CreditCardsProcessingSystemParameters);
	Items.ConnectedDoorLockSystem.RowFilter = New FixedStructure("Workstation, DeviceType", Object.Ref, Enums.DeviceTypes.DoorLockSystemParameters);

	SetVisible();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	vID = 0;
	While vID < CurrentObject.CashRegisters.Count() Do
		vPMRow = CurrentObject.CashRegisters.Get(vID);
		If Not ValueIsFilled(vPMRow.CashRegister) Then
			CurrentObject.CashRegisters.Delete(vID);
		Else
			vID = vID + 1;
		EndIf;
	EndDo; 
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonGflAxComponent(PCommand)
	#If Not WebClient Then
		vGflAxSetupFileName = TempFilesDir() + "GflAxSetup.exe";
		Try
			vGflAxSetupFile = New File(vGflAxSetupFileName);
			If tcCommonFunctionOnClientServer.cmExists(vGflAxSetupFile) And vGflAxSetupFile.IsFile() Then
				DeleteFiles(vGflAxSetupFileName);
			EndIf;
			vTmpl = pmGetCommonTemplate("GflAx");
			vTmpl.Write(vGflAxSetupFileName);
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("GflAx", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
		BeginRunningApplication(New NotifyDescription, vGflAxSetupFileName); 
	#EndIf 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonTCPIPComponents(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = CommonDir();
		vExtComponentName = vDir + "cswskax6.ocx";
		vExtComponentArchiveName = vDir + "TCPIP.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("TCPIP");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip ocx from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					Status(NStr("en='TCP/IP components are copied OK!';ru='ActiveX компоненты поддержки протокола TCP/IP скопированы успешно!';de='Die Active-X-Komponente für die Unterstützung des TCP/IP-Protokolls wurde erfolgreich kopiert!'"));
					// Try to register component
					System("regsvr32 /s " + """" + vExtComponentName + """", vDir);
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(,NStr("en='Components setup completed successfully!';ru='Установка компонент выполнена успешно!';de='Installation der Komponenten erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("TCP/IP", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonTCPIP_V10_X64_Components(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = CommonDir();
		vExtComponentName = vDir + "cswskx10.ocx";
		vExtComponentArchiveName = vDir + "TCPIP10_x64.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("TCPIP_V10_X64");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip ocx from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					Status(NStr("en='TCP/IP components are copied OK!';ru='ActiveX компоненты поддержки протокола TCP/IP скопированы успешно!';de='Die Active-X-Komponente für die Unterstützung des TCP/IP-Protokolls wurde erfolgreich kopiert!'"));
					// Try to register component
					System("regsvr32 /s " + """" + vExtComponentName + """", vDir);
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(,NStr("en='Components setup completed successfully!';ru='Установка компонент выполнена успешно!';de='Installation der Komponenten erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("TCP/IP", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure // ButtonTCPIP_V10_X64_Components

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonTCPIP_V10_X86_Components(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = CommonDir();
		vExtComponentName = vDir + "cswskx10.ocx";
		vExtComponentArchiveName = vDir + "TCPIP10_x86.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("TCPIP_V10_X86");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip ocx from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					Status(NStr("en='TCP/IP components are copied OK!';ru='ActiveX компоненты поддержки протокола TCP/IP скопированы успешно!';de='Die Active-X-Komponente für die Unterstützung des TCP/IP-Protokolls wurde erfolgreich kopiert!'"));
					// Try to register component
					System("regsvr32 /s " + """" + vExtComponentName + """", vDir);
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(,NStr("en='Components setup completed successfully!';ru='Установка компонент выполнена успешно!';de='Installation der Komponenten erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("TCP/IP", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf

EndProcedure // ButtonTCPIP_V10_X86_Components

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonNorweqVisionTCPComponent(pCommand)
	#If Not WebClient  And Not MobileClient Then
		vDir = CommonDir();
		vExtComponentName = vDir + "VisionInt.dll";
		vExtComponentArchiveName = vDir + "NorweqVisionTCP.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("NorweqVisionTCP");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip dll from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					Status(NStr("en='Norweq Vision component copied OK!'; ru='ActiveX компонент подключения к системе Norweq Vision скопирован успешно!'"));
					// Try to register component
					System("regsvr32 /s " + """" + vExtComponentName + """", vDir);
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(, NStr("en='Component setup completed successfully!';ru='Установка компоненты выполнена успешно!';de='Installation der Komponente erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("NorweqVisionTCP", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Button1CScan(pCommand)
	#If Not WebClient And Not MobileClient Then 
		Try
			BeginInstallAddIn(New NotifyDescription(), "CommonTemplate.Scan1C"); // ACC:561
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("1CScan", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonRS232Component(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = TrimAll(CommonDir());
		vExtComponentName = vDir + "SPort.dll";
		vExtComponentArchiveName = vDir + "RS232.zip";
		vExtComponentDistrName = vDir + "install.bat";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("RS232");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip ocx from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					Status(NStr("en='RS232 components are copied OK!';ru='ActiveX компоненты поддержки протокола RS232 скопированы успешно!';de='Die Active-X-Komponente für die Unterstützung des RS232-Protokolls wurde erfolgreich kopiert!'"));
					// Try to install component
					BeginRunningApplication(New NotifyDescription, vExtComponentDistrName, vDir); 
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(,NStr("en='Component setup completed successfully!';ru='Установка компоненты выполнена успешно!';de='Installation der Komponente erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("RS232", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonPDFToPNGComponent(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = TrimAll(CommonDir());
		vExtComponentName = vDir + "pdftopng.exe";
		vExtComponentArchiveName = vDir + "pdftopng.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("pdftopng");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip exe from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(,NStr("en='Component setup completed successfully!';ru='Установка компоненты выполнена успешно!';de='Installation der Komponente erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorInfo();
			ShowMessageBox(,BriefErrorDescription(vErrorDescription));
			tcOnServer.cmWriteLogEventAtServer("RS232", , , , DetailErrorDescription(vErrorDescription));
		EndTry;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonSimpleCallsComponent(pCommand)
	#If Not WebClient And Not MobileClient Then
		vDir = CommonDir();
		vExtComponentName = vDir + "CTIControl.dll";
		vExtComponentArchiveName = vDir + "CTIControl.zip";
		Try
			vFile = New File(vExtComponentArchiveName);
			If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
				vTmpl = pmGetCommonTemplate("SimpleCalls");
				vTmpl.Write(vExtComponentArchiveName);
				// Check that component was copied successfully
				vFile = New File(vExtComponentArchiveName);
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
					// Unzip ocx from archive
					vArchive = New ZipFileReader(vExtComponentArchiveName);
					vArchive.ExtractAll(vDir, ZIPRestoreFilePathsMode.DontRestore);
					vArchive.Close();
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Simple Calls components are copied OK!'; ru = 'ActiveX компоненты поддержки ""Простые звонки"" скопированы успешно!'; de = 'Die Active-X-Komponente für die Unterstützung des wurde erfolgreich kopiert!'"));
					// Try to register component
					System("regsvr32 /s " + """" + vExtComponentName + """", vDir);
					// Delete archive
					DeleteFiles(vExtComponentArchiveName);
				EndIf;
			EndIf;
			ShowMessageBox(, NStr("en='Components setup completed successfully!';ru='Установка компонент выполнена успешно!';de='Installation der Komponenten erfolgreich ausgeführt!'"));
		Except
			vErrorDescription = ErrorDescription();
			tcCommonFunctionOnClientServer.TextMessage(vErrorDescription, MessageStatus.Attention);
			vErrorText = NStr("en = 'Program has to install additional components Simple calls! 
	                           |Your current Windows user do not have permissions to complete components installation process. 
	                           |Please logoff Windows, login again with <Administrator> or <Power user> privileges and run program again to complete installation process.
	                           |'; ru = 'Для того чтобы использовать ""Простые звонки"" программа должна установить дополнительные компоненты! 
	                           |У пользователя, под которым сейчас работаете в Windows, недостаточно прав для установки требуемых компонент. 
	                           |Пожалуйста выйдите из Windows, зайдите под пользователем с правами системного администратора или опытного пользователя и запустите программу. 
	                           |При новом запуске программа установит недостающие компоненты.
	                           |
	                           |Можете продолжить работу с программой в этой сессии как обычно, однако ""Простые Звонки"" работать не будут.'; de = 'Um die einfache Anrufe zu verwenden, muss das Programm zusätzliche Komponenten installieren!
	                           |Der Nutzer, unter dem Sie jetzt in Windows arbeiten, 
	                           |hat nicht ausreichend Rechte, um die erforderlichen Komponenten zu installieren.
	                           |Bitte verlassen Sie Windows, melden Sie sich als Nutzer mit Systemadministratorrechten oder eines erfahrenen Nutzers an und starten Sie das Programm.
	                           |
	                           |
	                           |Sie können die Arbeit mit dem Programm wie gewohnt in dieser Sitzung fortsetzen, jedoch wird die graphische Karte des Zimmerbestandes nicht angezeigt.'");
			ShowMessageBox(, vErrorText);
		EndTry;
	  #EndIf
EndProcedure // ButtonSimpleCallsComponent

// -----------------------------------------------------------------------------
&AtClient
Procedure SimpleCallsParameters(pCommand)
	vData =  tcSimpleCallsOnServer.GetParameters(Object.Ref);
	vData.Insert("Workstation", Object.Ref);
	OpenForm("CommonForm.tcSimpleCallsParameters", New Structure("SelData", vData), ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SimpleCallsParameters

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetVisible()
	// Decoration pages
	vCount = 0;
	If Object.CashRegisters.Count()>0 Then
		vCount = Object.CashRegisters.Count(); 
		Items.PageCashRegistersAllowed.Title = Items.PageCashRegistersAllowed.Title + " (" + vCount + ")";
	EndIf;
	If ConnectedDoorLockSystems > 0 Then
		vCount = vCount + ConnectedDoorLockSystems;
		Items.PageDoorLockSystem.Title = Items.PageDoorLockSystem.Title + " (" + ConnectedDoorLockSystems + ")";
	EndIf;
	If ConnectedCreditCardProcessingSystems > 0 Then
		vCount = vCount + ConnectedCreditCardProcessingSystems;
		Items.PageCreditCardsProcessingSystem.Title = Items.PageCreditCardsProcessingSystem.Title + " (" + ConnectedCreditCardProcessingSystems + ")";
	EndIf;
	vID = 0;
	If Object.HasConnectionToImagesScanner Then
		vCount = vCount + 1;
		vID = vID + 1;
	EndIf;
	If Object.HasConnectionToIdentityCardsProcessingSystem Then
		vCount = vCount+1;
		vID = vID + 1;
	EndIf;
	If Object.HasConnectionToBarcodesScanner Then
		vCount = vCount+1;
		vID = vID + 1;
	EndIf;
	If Object.HasConnectionToCashAcceptors Then
		vCount = vCount+1;
		Items.PageConnectionToCashAcceptors.Title = Items.PageConnectionToCashAcceptors.Title + " (1)" 
	EndIf;
	If vID > 0 Then
		Items.PageConnectionToInputDevices.Title = Items.PageConnectionToInputDevices.Title+" (" + vID + ")";
	EndIf;	
	If vCount > 0 Then
		Items.PageDeviceConnectionSettings.Title = Items.PageDeviceConnectionSettings.Title+" (" + vCount + ")";
	EndIf;	
EndProcedure	

// -----------------------------------------------------------------------------
&AtServerNoContext
Function pmGetCommonTemplate(pNameTemplate)

	Return GetCommonTemplate(pNameTemplate);

EndFunction //  GetTemplate()

// -----------------------------------------------------------------------------
&AtClient
Function CommonDir()
	#If Not WebClient And Not MobileClient  Then
		vDir = Lower(BinDir());
		vSI = New SystemInfo();
		vAppVersion = Left(vSI.AppVersion, 3);
		If vAppVersion = "8.2" Then
			vCommonPos = Find(vDir, "\1cv82\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 5) + "\common\";
			EndIf;
		Else
			vCommonPos = Find(vDir, "\1cv8\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 4) + "\common\";
			EndIf;
		EndIf;
		Return vDir;
	#EndIf	
EndFunction // cmCommonDir

// -----------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters) 	
	vRecordSet = InformationRegisters.ConnectedDevices.CreateRecordSet();
	vRecordSet.Filter.Workstation.Set(Object.Ref);
	For Each vRow in AllConnectedDevices Do 
		vNewRecord = vRecordSet.Add();
		vNewRecord.Workstation = vRow.WorkStation;
		vNewRecord.DeviceType = vRow.DeviceType;
		vNewRecord.DeviceSettings = vRow.DeviceSettings;
		vNewRecord.IsActive = vRow.IsActive;
	EndDo;	
	vRecordSet.Write();
EndProcedure //OnWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateNewRow(pCommand)
	If pCommand.Name = "AddCreditCardProcessingSystem" Then
		vDeviceType = PredefinedValue("Enum.DeviceTypes.CreditCardsProcessingSystemParameters");
	Else
		vDeviceType = PredefinedValue("Enum.DeviceTypes.DoorLockSystemParameters");
	EndIf;
	vParams = New Structure("DeviceType", vDeviceType);
	OpenForm("Catalog.Workstations.Form.tcDeviceCreatingForm", vParams, ThisObject, UUID);
EndProcedure //CreateNewRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectedDevicesDeviceSettingsStartChoice(Item, ChoiceData, StandardProcessing)
	vRow = AllConnectedDevices.FindByID(CurrenRowNumber);
	vEnumRef = vRow.DeviceType;
	vType = "CatalogRef." + ReturnFilterStatusName(vEnumRef);
	Item.TypeRestriction = New TypeDescription(vType);
EndProcedure //ConnectedDevicesDeviceSettingsStartChoice

// -----------------------------------------------------------------------------
&AtServer
Function ReturnFilterStatusName(pEnumRef)
	vMetadataName = pEnumRef.Metadata().Name;
	vManagerName = "EnumManager." + vMetadataName;
	vManager = New (vManagerName); 
	vName = pEnumRef.Metadata().EnumValues[vManager.IndexOf(pEnumRef)].Name;

	Return vName;
Endfunction //ReturnFilterStatusName

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectedDevicesOnActivateRow(Item)
	CurrenRowNumber = Item.CurrentRow;
EndProcedure //ConnectedDevicesOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	vNewRow = AllConnectedDevices.Add();
	vNewRow.Workstation = Object.Ref;
	vNewRow.DeviceType = SelectedValue.DeviceType;
	vNewRow.DeviceSettings = SelectedValue.DeviceSettings;
	vNewRow.IsActive = SelectedValue.IsActive;
EndProcedure //ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenDeviceSettings(Command)
	If Command.Name = "OpenDoorLockSystemDeviceSettings" Then
		vRow = AllConnectedDevices.FindByID(Items.ConnectedDoorLockSystem.CurrentRow);
	Else
		vRow = AllConnectedDevices.FindByID(Items.ConnectedCreditCardProcessingSystem.CurrentRow);
	EndIf;
	ShowValue(, vRow.DeviceSettings);
EndProcedure //OpenDeviceSettings

#EndRegion
