#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//
Procedure ReadingAndWritingToRegister(pSourceNode = Undefined, pTargetNode = Undefined) Export 
	vEndDateTime = CurrentSessionDate() + 300; 
	While True Do
		
		ExchangePlansProcessing.ExchangePlansMessageReader(pSourceNode, pTargetNode);
		
		ExchangePlansProcessing.ExchangePlansMessageWriter(pSourceNode, pTargetNode);	
		
		If vEndDateTime > CurrentSessionDate() Then
			cmWait(3); 
		Else
			Break;	
		EndIf;
	EndDo;
EndProcedure // ReadingAndWritingToRegister

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//
Procedure ReceivingAndSendingMessageChanges(pSourceNode = Undefined, pTargetNode = Undefined) Export 
	vEndDateTime = CurrentSessionDate() + 300; 
	While True Do
		
		ExchangePlansProcessing.ExchangePlansReadMessage(pSourceNode, pTargetNode);
		
		ExchangePlansProcessing.ExchangePlansSendMessage(pSourceNode, pTargetNode);
		
		If vEndDateTime > CurrentSessionDate() Then
			cmWait(3); 
		Else
			Break;	
		EndIf;
	EndDo;	
EndProcedure // ReceivingAndSendingMessageChanges

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//
Procedure ExchangePlansReadMessage(pSourceNode = Undefined, pTargetNode = Undefined) Export
	Try
		vSysAdmsDepartment = Constants.SystemAdministratorsDepartment.Get();
		
		If ValueIsFilled(pSourceNode) And ValueIsFilled(pTargetNode) Then
			Try
				SendNodeMessageReadFile(pSourceNode, pTargetNode, vSysAdmsDepartment);
			Except
				AddError(pSourceNode, pTargetNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
			EndTry;
		Else
			For Each vExchangePlan In ExchangePlans Do
				vThisNode = vExchangePlan.ThisNode();
				If Not vThisNode.DeletionMark And vThisNode.OnlineSyncIsActive Then
					vTargetNodes = vExchangePlan.GetExchangePlanNodes(, vThisNode);
					For Each vTargetNodeRef In vTargetNodes Do
						Try
							vTargetNode = vTargetNodeRef; 
							If vTargetNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP Or vTargetNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local Then
								SendNodeMessageReadFile(vThisNode, vTargetNodeRef, vSysAdmsDepartment);
							EndIf;
						Except
							AddError(vThisNode, vTargetNodeRef, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
						EndTry;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	Except
		AddError(,, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure //ExchangePlansSendMessage

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//
Procedure ExchangePlansMessageReader(pSourceNode = Undefined, pTargetNode = Undefined) Export
	vSysAdmsDepartment = Constants.SystemAdministratorsDepartment.Get();	
	
	vNotReadMessage = New ValueList();
	
	// Get exchange plan data list
	vExchangePlanDataRow = InformationRegisters.ExchangePlanData.GetData(pSourceNode, pTargetNode, False, True, False);
	
	// Try to read changes
	While vExchangePlanDataRow.Next() Do
		If vNotReadMessage.FindByValue(vExchangePlanDataRow.ReceiverNode) = Undefined Then
			Try
				NodeMessageReader(vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, vExchangePlanDataRow.ReceiverNode, vExchangePlanDataRow.XMLValue.Get());	
			Except
				AddError(vExchangePlanDataRow.SenderNode, vExchangePlanDataRow.ReceiverNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
				vNotReadMessage.Add(vExchangePlanDataRow.ReceiverNode);
			EndTry;	
		EndIf;
	EndDo;
EndProcedure // ExchangePlansMessageReader

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//
Procedure ExchangePlansMessageWriter(pSourceNode = Undefined, pTargetNode = Undefined) Export
	Try
		vMessage = "";
		// Get system administrators department
		vSysAdmsDepartment = Constants.SystemAdministratorsDepartment.Get();
		If ValueIsFilled(pSourceNode) And ValueIsFilled(pTargetNode) Then
			Try
				NodeMessageWriter(pSourceNode, pTargetNode);
			Except
				AddError(pSourceNode, pTargetNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
			EndTry;
		Else
			// Try to find master node for this exchange plan
			vMasterNode = ExchangePlans.MasterNode();
			// Do for each exchange plan
			For Each vExchangePlan In ExchangePlans Do
				// Try to understand if current node is master or not
				vThisNode = vExchangePlan.ThisNode();
				If Not vThisNode.DeletionMark And vThisNode.OnlineSyncIsActive Then
					If Not ValueIsFilled(vMasterNode) Or vThisNode = vMasterNode Then
						vTargetNodes = vExchangePlan.GetExchangePlanNodes(, vThisNode);
						// Try to write changes to all other nodes in exchange plan
						For Each vTargetNodeRef In vTargetNodes Do
							Try  
								NodeMessageWriter(vThisNode, vTargetNodeRef);
							Except
								AddError(vThisNode, vTargetNodeRef, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
							EndTry;
						EndDo;
					Else
						// Send changes to the master node only
						Try
							NodeMessageWriter(vThisNode, vMasterNode);
						Except 
							AddError(vThisNode, vMasterNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
						EndTry;
					EndIf;
				EndIf;
			EndDo; 
		EndIf; 
	Except
		AddError(,, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure // ExchangePlansMessageWriter

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSourceNode	 - ExchangePlanRef	 - Source node
//  pTargetNode	 - ExchangePlanRef	 - Target node
//  pDoCallBack	 - Boolean			 - Do call back
//
Procedure ExchangePlansSendMessage(pSourceNode = Undefined, pTargetNode = Undefined) Export
	Try
		vSysAdmsDepartment  = Constants.SystemAdministratorsDepartment.Get();
		If ValueIsFilled(pSourceNode) And ValueIsFilled(pTargetNode) Then
			Try
				NodeMessageSend(ExchangePlans[pSourceNode.Metadata().Name], pSourceNode, pTargetNode);
			Except
				AddError(pSourceNode, pTargetNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
			EndTry
		Else
			// Do for each exchange plan
			For Each vExchangePlan In ExchangePlans Do
				Try
					vThisNode = vExchangePlan.ThisNode();
					If Not vThisNode.DeletionMark And vThisNode.OnlineSyncIsActive Then
						NodeMessageSend(vExchangePlan, vThisNode);
					EndIf;
				Except
					AddError(vThisNode,, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
				EndTry;
			EndDo;
		EndIf; 
	Except
		AddError(,, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure // ExchangePlansMessageReader

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Null			 	 - The changed data
//  pHotel			 - CatalogRef.Hotels - Hotel
//  pReceiverNode	 - ExchangePlanRef	 - Exchange plan
//
Procedure ExchangePlansRecordChanges(pData, pHotel = Undefined, pReceiverNode = Undefined) Export
	If pReceiverNode <> Undefined Then
		vThisNode = GetThisNode(pReceiverNode);
		If Not vThisNode.DeletionMark And vThisNode.OnlineSyncIsActive Then
			If Not ValueIsFilled(pHotel) Or pHotel = pReceiverNode.Hotel Then
				ExchangePlans.RecordChanges(pReceiverNode, pData);
			EndIf;
		EndIf;
	Else
		vTargetNodesArr = New Array;
		
		For Each vExchangePlan In ExchangePlans Do
			vThisNode = vExchangePlan.ThisNode();
			If Not vThisNode.DeletionMark And vThisNode.OnlineSyncIsActive Then
				If vExchangePlan.CheckContainsInContent(pData.Metadata()) Then
					vTargetNodes = vExchangePlan.GetExchangePlanNodes(pHotel, vThisNode);
					For Each vTargetNodeRef In vTargetNodes Do
						vTargetNodesArr.Add(vTargetNodeRef);
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		
		pData.DataExchange.Recipients.AutoFill = False;
		pData.DataExchange.Recipients.Clear();
		
		If vTargetNodesArr.Count() > 0 Then
			For Each vTargetNode In vTargetNodesArr Do
				pData.DataExchange.Recipients.Add(vTargetNode);
			EndDo;
		EndIf;
	EndIf;
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Function ExchangePlansWriteConfigurationChanges(pNode, pPath, pFileName, pExchangeFileName, pUseZip, pZipPwd, pUUID, pUseFTP, pInternetConnectionSettings, 
	pFTPAddress, pFTPPort, pFTPUser, pFTPPwd, pUsePassiveMode, pFTPConnectionTimeout) Export 
	If Not ValueIsFilled(pNode) Then
		Raise NStr("en='Node to send changes to is not set!';ru='Не выбран узел для отправки изменений!';de='Kein Knoten zum Versenden von Änderungen ist gewählt!'");
	EndIf;
	
	// Get and check this node
	vThisNode = GetThisNode(pNode);
	If vThisNode = Undefined Then
		Raise NStr("en='<This node> is not defined for the current configuration!';ru='В текущей конфигурации не определен <Этот узел>!';de='In der aktuellen Konfiguration ist <Dieser Knoten> nicht festgelegt!'");
	EndIf;
	If pNode = vThisNode Then
		Raise NStr("en='Node to send changes to should not be this node!';ru='Нельзя отправлять изменения в текущий узел!';de='Änderungen dürfen nicht an den aktuellen Knoten gesendet werden!'");
	EndIf;
	
	vTempAddress = "";
	
	// Get temporal directory path and initialize file name
	vTempDirPath = TrimAll(TempFilesDir());
	vTempDirPath = StrReplace(vTempDirPath, "\", "/");
	If Right(vTempDirPath, 1) <> "/" Then
		vTempDirPath = vTempDirPath + "/";
	EndIf;
	
	// Check path to write data to
	vTargetAddress = StrReplace(TrimAll(pPath), "\", "/");
	If Right(vTargetAddress, 1) <> "/" Then
		vTargetAddress = vTargetAddress + "/";
	EndIf;
	
	// Initialize file name
	pFileName = "Message_" + Upper(TrimAll(vThisNode.Code)) + "_" + Upper(TrimAll(pNode.Code));
	
	// Build file name to be used further
	pExchangeFileName = pFileName + ?(pUseZip, ".zip", ".xml");
	
	// Delete temp files left from a previous run
	RemoveTempExchangeFiles(vTempDirPath + pFileName, pUseZip);
	
	ChangeIgnoreMessagesWithChanges(pNode, True);
	
	vXMLWriter = New XMLWriter(); 
	vXMLWriter.OpenFile(vTempDirPath + pFileName + ".xml"); 
	vXMLWriter.WriteXMLDeclaration();
	vMessageWriter = ExchangePlans.CreateMessageWriter();
	vMessageWriter.BeginWrite(vXMLWriter, pNode);
	
	ExchangePlans.WriteChanges(vMessageWriter, 0);
	
	vMessageWriter.EndWrite();
	vXMLWriter.Close(); 
	
	ChangeIgnoreMessagesWithChanges(pNode, False);
	
	// Zip file with changes if necessary
	If pUseZip Then
		vArchive = New ZipFileWriter(vTempDirPath + pFileName + ".zip", pZipPwd, , ZIPCompressionMethod.Deflate, ZIPCompressionLevel.Maximum, ZIPEncryptionMethod.AES256);
		vArchive.Add(vTempDirPath + pFileName + ".xml", ZIPStorePathMode.DontStorePath);
		vArchive.Write();
	EndIf;
	
	// Copy file to the FTP or file target directory
	If Not IsBlankString(vTargetAddress) Then
		If pUseFTP Then
			vProxy = cmGetInternetProxy(pInternetConnectionSettings, False, pFTPAddress);
			vFTPServer = Undefined;
			If vProxy <> Undefined Then
				vFTPServer = New FTPConnection(pFTPAddress, pFTPPort, pFTPUser, pFTPPwd, vProxy, pUsePassiveMode, pFTPConnectionTimeout);
			Else
				vFTPServer = New FTPConnection(pFTPAddress, pFTPPort, pFTPUser, pFTPPwd, , pUsePassiveMode, pFTPConnectionTimeout);
			EndIf;
			// Delete file left from previous run
			If vFTPServer.FindFiles(vTargetAddress + pExchangeFileName).Count() > 0 Then
				vFTPServer.Delete(vTargetAddress + pExchangeFileName);
			EndIf;
			// Put file to server
			vFTPServer.Put(vTempDirPath + pExchangeFileName, vTargetAddress + pExchangeFileName);
		Else
			vTempAddress = PutToTempStorage(New BinaryData(vTempDirPath + pExchangeFileName), ?(ValueIsFilled(vTempAddress), vTempAddress, pUUID));
		EndIf;
	EndIf;
	
	// Delete temp files
	RemoveTempExchangeFiles(vTempDirPath + pFileName, pUseZip);
	
	Return vTempAddress;
EndFunction // ExchangePlansWriteConfiguration

// --------------------------------------------------------------------------------
//
// Parameters:
//  pNode	 - ExchangePlanRef	 - Exchange plan
// 
// Returns:
//  ExchangePlanRef - This node
//
Function GetThisNode(pNode) Export
	Return ExchangePlans[pNode.Metadata().Name].ThisNode();
EndFunction // GetThisNode

// --------------------------------------------------------------------------------
//
// Parameters:
//  pNode	 - ExchangePlanRef	 - Exchange plan
//
Procedure SetMaster(pNode = Undefined) Export 
	ExchangePlans.SetMasterNode(pNode);
	RefreshMasterNode(pNode);
EndProcedure // SetMaster

// --------------------------------------------------------------------------------
//
// Parameters:
//  pNode	 - ExchangePlanRef	 - Exchange plan
//
Procedure ClearNodeChanges(pNode) Export 
	ExchangePlans.DeleteChangeRecords(pNode);
	vCurNodeObj = pNode.GetObject();    
	vCurNodeObj.SentNo = 0;
	vCurNodeObj.ReceivedNo = 0;
	vCurNodeObj.Write();	
EndProcedure // ClearNodeChanges

// --------------------------------------------------------------------------------
//
// Parameters:
//  pNode	 - ExchangePlanRef	 - Exchange plan
//
Procedure SetAllRecordChanges(pNode) Export  
	ExchangePlans.RecordChanges(pNode, Undefined);		
EndProcedure // SetAllRecordChanges

// --------------------------------------------------------------------------------
//
// Parameters:
//  pNode	 - ExchangePlanRef	 - Exchange plan
//
Procedure SetAllRecordChangesByFilter(pNode) Export  
	SetRecordChanges(Constants, "Constants", pNode);
	SetRecordChanges(Catalogs, "Catalogs", pNode);  
	SetRecordChanges(Documents, "Documents", pNode);
	SetRecordChanges(ChartsOfCharacteristicTypes, "ChartsOfCharacteristicTypes", pNode);
	SetRecordChanges(ChartsOfAccounts, "ChartsOfAccounts", pNode);		
	SetRecordChanges(InformationRegisters, "InformationRegisters", pNode);
	SetRecordChanges(AccumulationRegisters, "AccumulationRegisters", pNode);
	SetRecordChanges(AccountingRegisters, "AccountingRegisters", pNode);	
EndProcedure // SetAllRecordChangesByFilter

// --------------------------------------------------------------------------------
// 
// Returns:
//  Boolean - Result 
//
Function CheckExclusiveMode() Export 
	vResult = True;
	vIBConnections = GetInfoBaseSessions();
	vCurIBConNumber = InfoBaseConnectionNumber();
	For Each vCon In vIBConnections Do
		If vCon.ApplicationName <> "Config" And 
			vCon.ApplicationName <> "Designer" And 
			vCon.ConnectionNumber <> vCurIBConNumber Then
			vResult = False;
			Break;
		EndIf;
	EndDo;
	Return vResult;	
EndFunction // CheckExclusiveMode

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure AddError(pThisNode = Undefined, pTargetNodes = Undefined, pSysAdmsDepartment, pErrorText)
	vMessage = ?(ValueIsFilled(pThisNode), TrimAll(pThisNode.Code), "") + ?(ValueIsFilled(pTargetNodes), " -> " + TrimAll(pTargetNodes.Code), "") + ": " + NStr("en='Error processing on-line synchronization!';ru='Ошибка при выполнении on-line синхронизации!';de='Fehler bei der Durchführung der Online-Synchronisation!'") + Chars.LF + pErrorText;
	WriteLogEvent(NStr("en='OnlineSynchronization.Error'; de='OnlineSynchronization.Error'; ru='OnlineСинхронизация.Ошибка'"), EventLogLevel.Error, , , vMessage);
	tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.VeryImportant);
	If ValueIsFilled(pSysAdmsDepartment) Then
		cmSendMessageToDepartment(pSysAdmsDepartment, vMessage, , False);
	EndIf;  
EndProcedure // AddError

// --------------------------------------------------------------------------------
Procedure RemoveTempExchangeFiles(pFileName, pUseZip)
	vTempXML = New File(pFileName + ".xml");
	If tcCommonFunctionOnClientServer.cmExists(vTempXML) Then
		DeleteFiles(pFileName + ".xml");
	EndIf;
	If pUseZip Then
		vTempZIP = New File(pFileName + ".zip");
		If tcCommonFunctionOnClientServer.cmExists(vTempZIP) Then
			DeleteFiles(pFileName + ".zip");
		EndIf;
	EndIf;
EndProcedure // RemoveTempExchangeFiles

// --------------------------------------------------------------------------------
Procedure ChangeIgnoreMessagesWithChanges(pNode, pIgnoreMessagesWithChanges)
	pNodeObj = pNode.GetObject();
	pNodeObj.IgnoreMessagesWithChanges = pIgnoreMessagesWithChanges;
	pNodeObj.Write();	
EndProcedure // ChangeIgnoreMessagesWithChanges

// --------------------------------------------------------------------------------
Procedure NodeMessageWriter(pSenderNode, pReceiverNode)
	vIsEnd = False;
	While Not vIsEnd Do
		// Read source node changes
		vMessageFileName = GetTempFileName(".xml");
		
		// Write XML file with changes
		WriteLogEvent(NStr("en='Write node changes to file'; ru='Запись изменений в файл'; de='Speichern die Änderungen in Datei'"), EventLogLevel.Information, , , "Start write to " + vMessageFileName);	
		
		vXMLWriter = New XMLWriter(); 
		vXMLWriter.OpenFile(vMessageFileName); 
		vXMLWriter.WriteXMLDeclaration();
		vMessageWriter = ExchangePlans.CreateMessageWriter();
		vMessageWriter.BeginWrite(vXMLWriter, pReceiverNode);
		
		vNumber = 0;
		
		vData = New Array;
		vSelectChanges = ExchangePlans.SelectChanges(vMessageWriter.Recipient, vMessageWriter.MessageNo);
		
		While vSelectChanges.Next() Do
			vChangedData = vSelectChanges.Get(); 
			
			vFullNameArr = StrSplit(vChangedData.Metadata().FullName(), ".", False);
			If vFullNameArr[0] = "InformationRegister" Or vFullNameArr[0] = "AccountingRegister" Or vFullNameArr[0] = "AccumulationRegister" Then
				If vNumber <> 0 Then
					vNumber = vNumber + vChangedData.Count();
					If vNumber > pSenderNode.ObjectsInMessage Then
						Break;
					EndIf;
				EndIf;
			EndIf;
			
			WriteXML(vXMLWriter, vChangedData);
			vData.Add(vChangedData);
			
			vNumber = vNumber + 1;
			If vNumber >= pSenderNode.ObjectsInMessage Then
				Break;
			EndIf;
		EndDo; 
		
		If vNumber = 0 Then 
			vMessageWriter.CancelWrite();
			vXMLWriter.Close();
			DeleteFiles(vMessageFileName);
			Break;	
		EndIf;							
		
		vMessageWriter.EndWrite();
		vXMLWriter.Close();    
		
		// Check that xml was successful
		vMessageFile = New File(vMessageFileName);
		If tcCommonFunctionOnClientServer.cmExists(vMessageFile) Then
			WriteLogEvent(NStr("en='Write node changes to file'; ru='Запись изменений в файл'; de='Speichern die Änderungen in Datei'"), EventLogLevel.Information, , , "End write to " + vMessageFileName + ", file size in bytes is " + vMessageFile.Size());
		Else
			Raise NStr("en = 'Failed to open file with changes!'; de = 'Datei mit Änderungen konnte nicht geöffnet werden!'; ru = 'Не удалось открыть файл с изменениями!'");
		EndIf;
		
		// Zip and encript file with changes if necessary
		vMessageZIPFileName = GetTempFileName(".zip");  
		
		// Write zip file with XML 
		vZipFileWriter = New ZipFileWriter(vMessageZIPFileName, TrimAll(pReceiverNode.DataExchangePassword), , ZIPCompressionMethod.Deflate, ZIPCompressionLevel.Maximum, ZIPEncryptionMethod.AES256);
		vZipFileWriter.Add(vMessageFileName, ZIPStorePathMode.DontStorePath);
		vZipFileWriter.Write();
		WriteLogEvent(NStr("en='Write node changes to file'; ru='Запись изменений в файл'; de='Speichern die Änderungen in Datei'"), EventLogLevel.Information, , , "End of zipping file " + vMessageFileName);
		
		// Check that zip was successfull
		vBinaryData = Undefined;
		vFileSize = 0;
		vZIPFileReader = New ZipFileReader(vMessageZIPFileName, TrimAll(pReceiverNode.DataExchangePassword));
		If vZIPFileReader.Items.Count() > 0 Then
			vZIPFileReader.Close();
			vMessageZIPFile = New File(vMessageZIPFileName);
			vFileSize = vMessageZIPFile.Size();
			// Read binary data from zip file
			vBinaryData = New BinaryData(vMessageZIPFileName);
		Else
			Raise NStr("en='Failed to zip exchange file data!'; ru='Ошибка при упаковке и сжатии файла с изменениями!'; de='Fehler bei zippen Dateien mit Änderungen!'");
		EndIf;
		WriteLogEvent(NStr("en='Write node changes to file'; ru='Запись изменений в файл'; de='Speichern die Änderungen in Datei'"), EventLogLevel.Information, , , "End of zip file consistency check " + vMessageZIPFileName);
		
		// Save file with changes
		InformationRegisters.ExchangePlanData.WriteData(pReceiverNode.SentNo, pSenderNode, pReceiverNode, vBinaryData,  Round(vFileSize / 1024, 2, RoundMode.Round15as20)); 
		
		ExchangePlans.DeleteChangeRecords(pReceiverNode, vData); 
		
		DeleteFiles(vMessageFileName);
		DeleteFiles(vMessageZIPFileName);
	EndDo;
EndProcedure // NodeMessageWriter

// --------------------------------------------------------------------------------
Procedure NodeMessageReader(pMessageNo, pSenderNode, pReceiverNode, pXMLValue)
	If pXMLValue = Undefined Then
		Raise NStr("en = 'Error reading file with changes.'; de = 'Fehler beim Lesen der Datei mit Änderungen.'; ru = 'Ошибка чтения файла с изменениями.'");	
	EndIf; 
	
	// Zip and encript file with changes if necessary
	vMessageZIPFileName = GetTempFileName(".zip");	
	pXMLValue.Write(vMessageZIPFileName);
	
	vTempFilesDir = TempFilesDir() + "\";
	
	vZIPFileReader = New ZipFileReader(vMessageZIPFileName, TrimAll(pReceiverNode.DataExchangePassword));
	For Each vItem In vZIPFileReader.Items Do		
		vZIPFileReader.Extract(vItem, vTempFilesDir);
		
		vXMLReader = New XMLReader(); 
		vXMLReader.OpenFile(vTempFilesDir + vItem.FullName);
		vMessageReader = ExchangePlans.CreateMessageReader();
		vMessageReader.BeginRead(vXMLReader); 
		
		If vMessageReader.Sender <> pSenderNode Then
			Raise NStr("en='Wrong node in the data exchange file!';ru='Неверный узел в файле обмена данными!';de='Falscher Knoten in der Datenaustauschdatei!'");
		EndIf;	
		
		While CanReadXML(vXMLReader) Do 
			vData = ReadXML(vXMLReader); 
			
			vData.DataExchange.Sender = vMessageReader.Sender;
			vData.DataExchange.Load = True;
			vData.Write();
		EndDo;
		
		vMessageReader.EndRead();
		vXMLReader.Close();
		
		If pReceiverNode.DeleteMessageAfterConfirmation Then
			InformationRegisters.ExchangePlanData.DeleteData(pMessageNo, pSenderNode, pReceiverNode);	
		Else
			InformationRegisters.ExchangePlanData.UpdateData(pMessageNo, pSenderNode, pReceiverNode,,,,,,,, True, CurrentSessionDate());
		EndIf;
		
		DeleteFiles(vTempFilesDir + vItem.FullName);	
	EndDo;
	DeleteFiles(vMessageZIPFileName);
EndProcedure // NodeMessageWriter

// --------------------------------------------------------------------------------
Procedure NodeMessageSend(pExchangePlan, pSenderNode, pReceiverNode = Undefined)
	vSysAdmsDepartment = Constants.SystemAdministratorsDepartment.Get();
	
	vExchangePlanDataList = InformationRegisters.ExchangePlanData.GetData(pSenderNode, pReceiverNode, False, False, False, True);
	
	vReceiverNodeList = vExchangePlanDataList.Copy(, "ReceiverNode");
	vReceiverNodeList.GroupBy("ReceiverNode");
	
	For Each vItem In vReceiverNodeList Do
		Try
			vReceiverNode = vItem.ReceiverNode;
			If ValueIsFilled(vReceiverNode) Then
				If ValueIsFilled(vReceiverNode.ExchangePlanDeliveryType) Then
					vExchangePlanDataArr = vExchangePlanDataList.FindRows(New Structure("ReceiverNode", vReceiverNode));
					For Each vExchangePlanDataRow In vExchangePlanDataArr Do
						vResult = False; 
						If vReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP Or vReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local Then
							vResult = SendNodeMessageSendFile(vExchangePlanDataRow.MessageNo, pSenderNode, vReceiverNode, vExchangePlanDataRow.XMLValue.Get(), vSysAdmsDepartment); 		
						ElsIf vReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.WebService Then	
							vResult = SendNodeMessageSendWebService(pExchangePlan, vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, 
							vExchangePlanDataRow.ReceiverNode, vExchangePlanDataRow.XMLValue.Get(), vExchangePlanDataRow.FileSize);
						ElsIf vReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.HTTP Then	
							vResult = SendNodeMessageSendHTTP(pExchangePlan, vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, 
							vExchangePlanDataRow.ReceiverNode, vExchangePlanDataRow.XMLValue.Get(), vExchangePlanDataRow.FileSize); 
						ElsIf vReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.ESB1CIntegrationService Then
							If Not vExchangePlanDataRow.IsSentToESB Then
								vResult = SendNodeMessageSendESB1CIntegrationService(pExchangePlan, vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, 
								vExchangePlanDataRow.ReceiverNode, vExchangePlanDataRow.XMLValue.Get(), vExchangePlanDataRow.FileSize);
							EndIf;
						EndIf;
						If vResult Then
							If vExchangePlanDataRow.SenderNode.DeleteMessageAfterConfirmation Then
								InformationRegisters.ExchangePlanData.DeleteData(vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, vExchangePlanDataRow.ReceiverNode);	
							Else
								InformationRegisters.ExchangePlanData.UpdateData(vExchangePlanDataRow.MessageNo, vExchangePlanDataRow.SenderNode, 
								vExchangePlanDataRow.ReceiverNode,,,, True, CurrentSessionDate());
							EndIf;	
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		Except
			AddError(, vReceiverNode, vSysAdmsDepartment, cmGetRootErrorDescription(ErrorInfo()));    
		EndTry;
	EndDo;	 
EndProcedure // NodeMessageSend

// --------------------------------------------------------------------------------
Procedure SendNodeMessageReadFile(pSenderNode, pReceiverNode, pSysAdmsDepartment)
	vFilesArr = New Array;	
	vFTPServer = Undefined;
	If pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local Then 
		vSourceAddress = GetSourceAddress(TrimAll(pReceiverNode.Path));
		vFilesArr = FindFiles(TrimAll(vSourceAddress), TrimAll(pReceiverNode.Code) + "_" + TrimAll(pSenderNode.Code) + "_*.zip");
	ElsIf pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP Then
		vProxy = cmGetInternetProxy(, False, TrimAll(pReceiverNode.DataExchangeFTPHost));
		vDataExchangeFTPPort = ?(pReceiverNode.DataExchangeFTPPort = 0, 21, pReceiverNode.DataExchangeFTPPort);
		
		vFTPServer = New FTPConnection(TrimAll(pReceiverNode.DataExchangeFTPHost), vDataExchangeFTPPort, TrimAll(pReceiverNode.DataExchangeFTPUser), TrimAll(pReceiverNode.DataExchangeFTPUserPassword), vProxy, pReceiverNode.DataExchangeFTPUsePassiveMode);		
		vSourceAddress = GetSourceAddress(TrimAll(pReceiverNode.DataExchangeFTPPath)); 
		
		vFilesArr = vFTPServer.FindFiles(vSourceAddress, TrimAll(pReceiverNode.Code) + "_" + TrimAll(pSenderNode.Code) + "_*.zip");
	EndIf;
	For Each vFile In vFilesArr Do
		If vFile.IsFile() Then 
			vSentNo = GetSentNoByFileName(vFile.BaseName);
			If pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local Then
				InformationRegisters.ExchangePlanData.WriteData(vSentNo, pReceiverNode, pSenderNode, New BinaryData(vFile.FullName),  Round(vFile.Size() / 1024, 2, RoundMode.Round15as20), False, '00010101', True, CurrentSessionDate(), False, '00010101');			
				DeleteFiles(vFile.FullName);	
			ElsIf pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP Then 
				vMessageZIPFileName = GetTempFileName(".zip");
				vFTPServer.Get(vFile.FullName, vMessageZIPFileName);
				InformationRegisters.ExchangePlanData.WriteData(vSentNo, pReceiverNode, pSenderNode, New BinaryData(vMessageZIPFileName),  Round(vFile.Size() / 1024, 2, RoundMode.Round15as20), False, '00010101', True, CurrentSessionDate(), False, '00010101');
				DeleteFiles(vMessageZIPFileName);
				vFTPServer.Delete(vFile.FullName);
			EndIf; 
		EndIf;		
	EndDo; 
EndProcedure // SendNodeMessageReadFile

// --------------------------------------------------------------------------------
Function GetSentNoByFileName(pFileName)
	vFileNameArr = StrSplit(pFileName, "_", False);
	Return Number(vFileNameArr[2]); 
EndFunction // SendNodeMessageSendFTP

// --------------------------------------------------------------------------------
Function SendNodeMessageSendFile(pMessageNo, pSenderNode, pReceiverNode, pXMLValue, pSysAdmsDepartment)
	If pXMLValue <> Undefined Then
		vMessageZIPFileName = TrimAll(pSenderNode.Code) + "_" + TrimAll(pReceiverNode.Code) + "_" + Format(pMessageNo, "NFD=0; NZ=0; NG=") + ".zip"; 
		If pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local And ValueIsFilled(pReceiverNode.Path) Then 
			vSourceAddress = GetSourceAddress(TrimAll(pReceiverNode.Path));	
			pXMLValue.Write(vSourceAddress + vMessageZIPFileName);	
		ElsIf pReceiverNode.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP And ValueIsFilled(pReceiverNode.DataExchangeFTPHost) Then
			vProxy = cmGetInternetProxy(, False, TrimAll(pReceiverNode.DataExchangeFTPHost));
			vDataExchangeFTPPort = ?(pReceiverNode.DataExchangeFTPPort = 0, 21, pReceiverNode.DataExchangeFTPPort);
			
			vFTPServer = New FTPConnection(TrimAll(pReceiverNode.DataExchangeFTPHost), vDataExchangeFTPPort, TrimAll(pReceiverNode.DataExchangeFTPUser), TrimAll(pReceiverNode.DataExchangeFTPUserPassword), vProxy, pReceiverNode.DataExchangeFTPUsePassiveMode);		
			vSourceAddress = GetSourceAddress(TrimAll(pReceiverNode.DataExchangeFTPPath)); 
			
			vTempFile = GetSourceAddress(TempFilesDir()) + vMessageZIPFileName;
			
			pXMLValue.Write(vTempFile);
			
			vFTPServer.Put(vTempFile, vSourceAddress);  
			
			DeleteFiles(vTempFile);
		Else
			Raise NStr("en = 'Not filled settings: '; de = 'Einstellungen nicht abgeschlossen: '; ru = 'Не заполнены настройки: '") + TrimAll(pReceiverNode);		
		EndIf;	
	EndIf;   
	Return True;
EndFunction // SendNodeMessageSendFTP

// --------------------------------------------------------------------------------
Function SendNodeMessageSendWebService(pExchangePlan, pMessageNo, pSenderNode, pReceiverNode, pXMLValue, pFileSize)
	If pXMLValue <> Undefined Then 
		vTargetWSDLHostAddress = TrimAll(pReceiverNode.DataExchangeWSDLHost);
		If ValueIsFilled(vTargetWSDLHostAddress) Then
			vExchangePlanName = Mid(String(pExchangePlan), 21);
			
			// Create WEB-services proxy
			vWSDef = New WSDefinitions(vTargetWSDLHostAddress);
			vWSProxy = New WSProxy(vWSDef, "http://www.1chotel.ru/ws/interfaces/dataexchange/", "DataExchangeInterfaces", "DataExchangeInterfacesSoap");
			
			// Call web-service to transfer changes to the target node
			WriteLogEvent(NStr("en='Synchronize webservice call'; ru='Вызов web-службы Synchronize'; de='Web-Dienst Synchronize anrufen'"), EventLogLevel.Information, , , "" + pExchangePlan + ", " + "Message_" + TrimR(pSenderNode.Code) + "_" + TrimR(pReceiverNode.Code));
			vResult = vWSProxy.Synchronize(vExchangePlanName, pMessageNo, TrimAll(pSenderNode.Code), TrimAll(pReceiverNode.Code), Base64String(pXMLValue), pFileSize);
			If vResult <> "OK" Then
				WriteLogEvent(NStr("en='Synchronize webservice call'; ru='Вызов web-службы Synchronize'; de='Web-Dienst Synchronize anrufen'"), EventLogLevel.Error, , , vResult);
				Raise NStr("en='Failed to receive synchronization confirmation reply!';ru='Не удалось получить подтверждение обработки команды синхронизации!';de='Die Bestätigung für die Bearbeitung des Synchronisationsbefehls konnte nicht eingehalten werden!'") + Chars.LF + vResult;
			EndIf;
			WriteLogEvent(NStr("en='Synchronize webservice call'; ru='Вызов web-службы Synchronize'; de='Web-Dienst Synchronize anrufen'"), EventLogLevel.Information, , , vResult); 
			
			Return True;
		Else
			Raise NStr("en = 'Data exchange service WSDL address not specified: '; de = 'WSDL-Adresse des Datenaustauschdienstes nicht angegeben: '; ru = 'Не указан адрес WSDL службы обмена данными: '") + TrimAll(pReceiverNode);	
		EndIf;	
	EndIf;
	Return False;
EndFunction // SendNodeMessageSendWebService 

// --------------------------------------------------------------------------------
Function SendNodeMessageSendHTTP(pExchangePlan, pMessageNo, pSenderNode, pReceiverNode, pXMLValue, pFileSize)
	If pXMLValue <> Undefined Then 
		vTargetHttpServer = TrimAll(pReceiverNode.HttpServer); 
		vTargetHttpAddress = TrimAll(pReceiverNode.HttpAddress);
		If ValueIsFilled(vTargetHttpServer) And ValueIsFilled(vTargetHttpAddress) Then
			vExchangePlanName = Mid(String(pExchangePlan), 21);
			
			vJSONStr = New Structure;
			vJSONStr.Insert("ExchangePlanName", vExchangePlanName);
			vJSONStr.Insert("MessageNo", pMessageNo);
			vJSONStr.Insert("SourceNodeCode", TrimAll(pSenderNode.Code));
			vJSONStr.Insert("TargetNodeCode", TrimAll(pReceiverNode.Code));
			vJSONStr.Insert("ChangedData", Base64String(pXMLValue));
			vJSONStr.Insert("FileSize", Int(pFileSize * 100));
			vJSON = MapToJSON(vJSONStr);
			
			vPort = pReceiverNode.HttpPort;
			If vPort <> 80 And vPort <> 0 Then
				vTargetHttpServer = vTargetHttpServer + ":" + Format(vPort, "NFD=0; NG=");
			EndIf;
			
			vSSL = Undefined;
			If pReceiverNode.HTTPUseSSL Then
				vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
			EndIf;
			
			vHTTPHeader = New Map();
			
			vHTTPConnection = New HTTPConnection(vTargetHttpServer,,,,, 15, vSSL);
			
			vHTTPRequest = New HTTPRequest(vTargetHttpAddress, vHTTPHeader);
			vHTTPRequest.SetBodyFromString(vJSON);
			
			// Call web-service to transfer changes to the target node
			WriteLogEvent(NStr("en='Synchronize webservice call'; ru='Вызов web-службы Synchronize'; de='Web-Dienst Synchronize anrufen'"), EventLogLevel.Information, , , "" + pExchangePlan + ", " + "Message_" + TrimR(pSenderNode.Code) + "_" + TrimR(pReceiverNode.Code));
			vHTTPResponse = vHTTPConnection.CallHTTPMethod("POST", vHTTPRequest); 
			If vHTTPResponse.StatusCode <> 200 Then 
				vResult = vHTTPResponse.GetBodyAsString();
				WriteLogEvent(NStr("en='Synchronize webservice call'; ru='Вызов web-службы Synchronize'; de='Web-Dienst Synchronize anrufen'"), EventLogLevel.Error, , , vResult);
				Raise NStr("en='Failed to receive synchronization confirmation reply!';ru='Не удалось получить подтверждение обработки команды синхронизации!';de='Die Bestätigung für die Bearbeitung des Synchronisationsbefehls konnte nicht eingehalten werden!'") + Chars.LF + vResult;
			EndIf; 
			
			Return True;
		Else
			Raise NStr("en = 'Data exchange service WSDL address not specified: '; de = 'WSDL-Adresse des Datenaustauschdienstes nicht angegeben: '; ru = 'Не указан адрес WSDL службы обмена данными: '") + TrimAll(pReceiverNode);	
		EndIf;	
	EndIf;
	Return False;
EndFunction // SendNodeMessageSendHTTP

// --------------------------------------------------------------------------------
Function SendNodeMessageSendESB1CIntegrationService(pExchangePlan, pMessageNo, pSenderNode, pReceiverNode, pXMLValue, pFileSize)
	If pXMLValue <> Undefined Then 
		vMessage = IntegrationServices.DataExchangeInterfaces.CreateMessage();
		
		vMessage.SenderCode = TrimAll(pSenderNode.Code);
		vMessage.RecipientCode = TrimAll(pReceiverNode.Code);
		
		vMessage.Parameters.Insert("ExchangePlanName", Mid(TrimAll(pExchangePlan), 21)); 
		vMessage.Parameters.Insert("MessageNo", pMessageNo);
		vMessage.Parameters.Insert("FileSize", Int(pFileSize * 100));
		
		vBodyStream = vMessage.GetBodyAsStream();		
		vDataStream = pXMLValue.OpenStreamForRead();
		
		vDataStream.CopyTo(vBodyStream);
		
		vBodyStream.Flush();
		vBodyStream.Close();
		vDataStream.Close();
		
		IntegrationServices.DataExchangeInterfaces.SenderNode.SendMessage(vMessage);
		
		InformationRegisters.ExchangePlanData.UpdateData(pMessageNo, pSenderNode, pReceiverNode, vMessage.ID, True, CurrentSessionDate());
	EndIf;
	Return False;
EndFunction // SendNodeMessageSendESB1CIntegrationService

// --------------------------------------------------------------------------------
Function MapToJSON(pMap)	
	vJSONWriter = new JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();	
EndFunction // MapToJSON

// --------------------------------------------------------------------------------
Procedure SetRecordChanges(pObject, pObjectName, pCurRef)  
	For Each vMetadata In Metadata[pObjectName] Do
		If ExchangePlans.CentralOfficeExchangePlan.CheckContainsInContent(vMetadata) Then 
			If pObjectName = "InformationRegisters" Or pObjectName = "AccumulationRegisters" Or pObjectName = "AccountingRegisters" Then				
				vDataSelectedArray = New Array;
				If pObjectName = "AccumulationRegisters" Or pObjectName = "AccountingRegisters" Or 
					pObjectName = "InformationRegisters" And vMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
					vDataSelectedArray.Add("Recorder");	
				Else
					For Each vDimension In vMetadata.Dimensions Do
						vDataSelectedArray.Add(vDimension.Name);	
					EndDo;	
				EndIf;  
				If pObjectName = "InformationRegisters" And vMetadata.MainFilterOnPeriod Then
					vDataSelectedArray.Add("Period");		
				EndIf;
				vQ = New Query;
				vQ.Text = StrTemplate("
				|SELECT
				|	%1
				|FROM
				|	%2 AS DataRegisters
				|
				|GROUP BY
				|	%1", StrConcat(vDataSelectedArray, ","), vMetadata.FullName()); 
				vSelection = vQ.Execute().Select();
				While vSelection.Next() Do
					vRecordSet = pObject[vMetadata.Name].CreateRecordSet();
					For Each vDataSelected In vDataSelectedArray Do 
						vRecordSet.Filter[vDataSelected].Value = vSelection[vDataSelected];
						vRecordSet.Filter[vDataSelected].Use = True;
					EndDo;
					pObject[vMetadata.Name].ExchangePlansRecordChanges(vRecordSet, pCurRef);
				EndDo; 
			ElsIf pObjectName = "Constants" Then
				pObject[vMetadata.Name].ExchangePlansRecordChanges(pObject[vMetadata.Name].CreateValueKey(), pCurRef);	
			Else
				vSelection = pObject[vMetadata.Name].Select();
				While vSelection.Next() Do
					pObject[vMetadata.Name].ExchangePlansRecordChanges(vSelection.Ref, pCurRef);
				EndDo;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // SetCatalogsRecordChanges

// --------------------------------------------------------------------------------
Procedure RefreshMasterNode(pNode = Undefined)
	Try
		vThisNodeCentralOfficeExchangePlan = ExchangePlans.CentralOfficeExchangePlan.ThisNode();	
		vThisNodeReplicationExchangePlan = ExchangePlans.ReplicationExchangePlan.ThisNode();
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CentralOfficeExchangePlan.Ref AS Ref
		|FROM
		|	ExchangePlan.CentralOfficeExchangePlan AS CentralOfficeExchangePlan
		|WHERE
		|	NOT CentralOfficeExchangePlan.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	ReplicationExchangePlan.Ref
		|FROM
		|	ExchangePlan.ReplicationExchangePlan AS ReplicationExchangePlan
		|WHERE
		|	NOT ReplicationExchangePlan.DeletionMark";
		vNodes = vQry.Execute().Unload();
		For Each vNodeRow In vNodes Do
			vNodeObj = vNodeRow.Ref.GetObject();
			If pNode = Undefined Then 
				If vNodeRow.Ref = vThisNodeCentralOfficeExchangePlan Or vNodeRow.Ref = vThisNodeReplicationExchangePlan Then
					vNodeObj.IsMaster = True;
				Else
					vNodeObj.IsMaster = False;	
				EndIf;
			ElsIf pNode = vNodeRow.Ref Then
				vNodeObj.IsMaster = True;
			Else
				vNodeObj.IsMaster = False;
			EndIf;
			vNodeObj.Write();
		EndDo;
	Except
		vErrorInfo = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(BriefErrorDescription(vErrorInfo));
	EndTry;
EndProcedure // RefreshMasterNode

// --------------------------------------------------------------------------------
Function GetSourceAddress(pPath)
	// Get exchange file path
	vSourceAddress = StrReplace(TrimAll(pPath), "\", "/");
	If Left(vSourceAddress, 1) = "/" Then
		vSourceAddress = Mid(vSourceAddress, 2);
	EndIf;
	If Right(vSourceAddress, 1) <> "/" Then
		vSourceAddress = vSourceAddress + "/";
	EndIf;
	Return vSourceAddress;
EndFunction // GetSourceAddress

#EndRegion
