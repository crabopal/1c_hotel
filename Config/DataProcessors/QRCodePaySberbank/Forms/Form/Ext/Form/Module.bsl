
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If NOT Active Then
		Debug = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure HttpCertificateFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("AttachingFileSystemExtensionResult", ThisForm));
EndProcedure // HttpCertificateFileStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckСonnections(pCommand)
	If Save_AtServer() Then 
		CheckСonnectionsAtServer();
	EndIf;
EndProcedure // CheckСonnections

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	
	If NOT CheckFilling() Then
		Return False;
	EndIf;
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();
				
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
				
		Obj.pmSaveDataProcessorAttributes();
		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Failed to save:" + vError);
		RollbackTransaction();   
		Return False;
	EndTry;	  
	Return True;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	vIntParObj									   = Object.ExternalInteraction.GetObject();
	vIntParObj.IsActive							   = Active;
	vIntParObj.Hotel							   = Hotel;
	vIntParObj.DebugMode						   = Debug;
	vIntParObj.OAuth_ClientID					   = OAuth_ClientID;
	vIntParObj.OAuth_ClientSecret				   = OAuth_ClientSecret;
	vIntParObj.HttpServer 					  	   = HttpServer;
	vIntParObj.WSHost							   = WSHost;
	vIntParObj.MaxLogLenght						   = MaxLogLenght;
	vIntParObj.HttpCertificateFile				   = HttpCertificateFile;
	vIntParObj.HttpCertificatePassword			   = HttpCertificatePassword;
	vIntParObj.Write();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel  								= Object.ExternalInteraction.Hotel;
	Active  							= Object.ExternalInteraction.IsActive;
	Debug  					   			= Object.ExternalInteraction.DebugMode;
	OAuth_ClientID   					= Object.ExternalInteraction.OAuth_ClientID;
	OAuth_ClientSecret   				= Object.ExternalInteraction.OAuth_ClientSecret;
	HttpServer 							= Object.ExternalInteraction.HttpServer; 
	WSHost								= Object.ExternalInteraction.WSHost;
	MaxLogLenght						= Object.ExternalInteraction.MaxLogLenght;
	HttpCertificateFile					= Object.ExternalInteraction.HttpCertificateFile;
	HttpCertificatePassword				= Object.ExternalInteraction.HttpCertificatePassword;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("FileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // AttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure FileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("InstallingFileSystemExtensionResult", ThisForm));
EndProcedure // FileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure InstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // InstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient                                                                 
Procedure OpenFileDialogToChooseFile()                                    
	vFindFile = New FileDialog(FileDialogMode.Open);
	vFindFile.Filter = NStr("en = 'Certificate file (*.PFX;*.P12;*.PEM)|*.PFX;*.P12;*.PEM'; de = 'Zertifikatsdatei (*.PFX;*.P12;*.PEM)|*.PFX;*.P12;*.PEM'; ru = 'Файл сертификата (*.PFX;*.P12;*.PEM)|*.PFX;*.P12;*.PEM'");
	vFindFile.FullFileName = HttpCertificateFile;
	vFindFile.CheckFileExist = True;
	vFindFile.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // AddressAndStreetsClassifierFileOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		HttpCertificateFile = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckСonnectionsAtServer()
	vObj = FormAttributeToValue("Object"); 
	vAccessToken = "";        
	vMessage = "";
	If Not vObj.GetAccessToken(?(ValueIsFilled(Object.ScopeCreate), Object.ScopeCreate, "https://api.sberbank.ru/qr/order.create"), vAccessToken, vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Works'; de = 'Funktioniert'; ru = 'Работает'"));
	EndIf;
EndProcedure // CheckСonnectionsAtServer

#EndRegion

