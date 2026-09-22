
#Region FormEventHandlers
	
// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Filter") And
	   Parameters.Filter.Property("GuestGroup") And
	   ValueIsFilled(Parameters.Filter.GuestGroup) Then
	    vCondition = "WHERE
					  |   GuestGroupAttachments.GuestGroup = &qGuestGroup ";
		GuestGroup = Parameters.Filter.GuestGroup;
	Else
		vСondition = "";
	EndIf;
	RunGuestGroupQuery(vCondition);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Printer = GetDefaultPrinter();
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PrinterStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	// Get printers	
	vPrintersList = New ValueList();
	vWSObj = New COMObject("WScript.Network"); 
	vPrinters = vWSObj.EnumPrinterConnections(); 
	i = 0;
	vPrintersAmount = vPrinters.Count();
	While i < vPrintersAmount-1 Do
		vPrintersList.Add(vPrinters.Item(i+1));
		i = i + 2; 
	EndDo; 
		
	vSelectedElem = ChooseFromList(vPrintersList, pItem);
	If vSelectedElem <> Undefined Then
		Printer = vSelectedElem.Value;
	EndIf;
EndProcedure // PrinterStartChoice

// --------------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	DocumentsTable.Clear();
	If Not IsBlankString(GuestGroup) Then
		vCondition = "WHERE
					  |   GuestGroupAttachments.GuestGroup = &qGuestGroup ";
	Else
		vCondition = "";
	EndIf;
	RunGuestGroupQuery(vCondition);
EndProcedure  // GuestGroupOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	GuestGroupOnChangeAtServer();
EndProcedure // GuestGroupOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectAll(pCommand)
	For Each vRow In DocumentsTable Do
		vRow.Print = True;
	EndDo;
EndProcedure // SelectAll

// --------------------------------------------------------------------------------
&AtClient
Procedure Deselect(pCommand)
	For Each vRow In DocumentsTable Do
		vRow.Print = False;
	EndDo;
EndProcedure // Deselect

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintDocs(pCommand)
	vCheckedFiles = New Array;
	For Each vRow In DocumentsTable Do
		If vRow.Print Then
			If vRow.FileName <> "" Then
				vCheckedFiles.Add(New Structure ("Period, Group, FileName, TempStorageAddress, LocalFullFileName", vRow.Period, vRow.Group));
			EndIf;		
		EndIf;
	EndDo;
	BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisForm, New Structure("CheckedFiles, TempFilesDir", vCheckedFiles, "")));
EndProcedure // PrintDocs

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='Браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisForm, pParam));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtServer
Procedure RunGuestGroupQuery(pCondition)
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	GuestGroupAttachments.GuestGroup.Ref AS GuestGroup,
	|	GuestGroupAttachments.FileName AS FileName,
	|	GuestGroupAttachments.Period AS Period
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments "  + pCondition +
    "ORDER BY
	|	Period";
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQryResult = vQry.Execute().Unload();
	For Each vRow In vQryResult Do
		vNewRow = DocumentsTable.Add();
		vNewRow.Group = vRow.GuestGroup;
		vNewRow.Period= vRow.Period;
		vNewRow.FileName = vRow.FileName;
	EndDo;
EndProcedure // RunGuestGroupQuery

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	pParam.TempFilesDir = pTempFilesDir;
	
	vFilesToBeObtained = PrepareFiles(pParam);
	
	BeginGetFilesFromServer(New NotifyDescription("OpenFileGettingFilesCompleted", ThisForm, pParam), vFilesToBeObtained, pParam.TempFilesDir);
EndProcedure // OpenFileGettingTempFilesDirCompleted

// --------------------------------------------------------------------------------
&AtServerNoContext
Function PrepareFiles(pParam)
	// Create array of files to transfer from server to the client
    vFilesToBeObtained = New Array();
	// Get temp storage address with file data
	For Each vRow In pParam.Checkedfiles Do
		vRow.FileName = "";
		vTempStorageAddress = GetFileTempStorageAddress(vRow.Period, vRow.Group, vRow.FileName);
		vRow.TempStorageAddress = vTempStorageAddress;
		// Build local temp file name
		vLocalFullFileName = pParam.TempFilesDir + vRow.FileName;
		vRow.LocalFullFileName = vLocalFullFileName;		
		vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTempStorageAddress);
		vFilesToBeObtained.Add(vFileToBeObtained);
	EndDo;
	
	Return vFilesToBeObtained;
EndFunction // PrepareFiles

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetFileTempStorageAddress(pPeriod, pGroup, rFileName)
    vRecord = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
	vRecord.Period = pPeriod;
	vRecord.GuestGroup = pGroup;
	vRecord.Read();
	If vRecord.Selected() Then
		rFileName = StrReplace(vRecord.FileName, " ", "");
		vBinaryData = vRecord.ExtFile.Get();
		Return PutToTempStorage(vBinaryData);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetFileTempStorageAddress

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pParam) Export
	// Print files
	For Each vFile In pTransferredFiles Do
	    AppShell = New COMObject("Shell.Application");
		vFileName = StrReplace(vFile.FullName, "/", "\");
		vResult = AppShell.ShellExecute(vFileName, """" + Printer + """", "", "printto", 0);
		Delay(1);
	EndDo;
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure Delay(pSeconds)
	cmWait(pSeconds);
EndProcedure // Delay

&AtClient
// --------------------------------------------------------------------------------
Function GetDefaultPrinter()
    vScript = New COMObject("MSScriptControl.ScriptControl");
    vScript.Language = "vbscript";                 
    vScript.AddCode("
         |Function GetDefaultPrinter()
         |GetDefaultPrinter=vbNullString
         |Set objWMIService=GetObject(""winmgmts:"" _
         |& ""{impersonationLevel=impersonate}!\\.\root\cimv2"")
         |Set colInstalledPrinters=objWMIService.ExecQuery _
         |(""Select * from Win32_Printer"")
         |For Each objPrinter in colInstalledPrinters
         |If objPrinter.Attributes and 4 Then
         |GetDefaultPrinter=objPrinter.Name
         |Exit For
         |End If
         |Next
         |End Function");
         
    Return TrimAll(vScript.run("GetDefaultPrinter"));
EndFunction // GetDefaultPrinter

#EndRegion
