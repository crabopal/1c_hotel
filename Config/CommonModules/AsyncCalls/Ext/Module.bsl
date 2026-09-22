
#Region Public

// --------------------------------------------------------------------------------
//  Function - Start background job
//
// Parameters:
//  pFunctionName		 - String	 - Function name (String)
//  pFunctionParameters	 - Array	 - Array of function parametrs (Array)
//  pBackgroundJobKey	 - UUID		 - UUID
//  pBacgroundJobName	 - String	 - If Undefined Job Name = Function Name (String)
//  pTempStorageAddress	 - String	 - Temporary storage address (String), if Undefined will generate address.
// 
// Returns:
//  Structure - {UUID, TempStorageAddress}
//
Function StartBackgroundJob(pFunctionName, pFunctionParameters = Undefined, pBackgroundJobKey = Undefined, pBacgroundJobName = Undefined, pTempStorageAddress = Undefined) Export	
 	vBackgroundJob = BackgroundJobs.Execute(pFunctionName, pFunctionParameters, pBackgroundJobKey, ?(IsBlankString(pBacgroundJobName), pFunctionName, pBacgroundJobName));
	
	If pTempStorageAddress = Undefined Then
		pTempStorageAddress = PutToTempStorage(Null);
	EndIf;
	
	Result = New Structure;
	Result.Insert("UUID", vBackgroundJob.UUID);
	Result.Insert("TempStorageAddress", pTempStorageAddress);
	Return Result;
EndFunction //  StartBackgroundJob()

// --------------------------------------------------------------------------------
//  Function - Start background job with record in register
//
// Parameters:
//  pObjectRef				 - String	 - Object ref (Ref)
//  pOperationName			 - String	 - Operation name to show in register (String)
//  pFunctionName			 - String	 - Function name (String)
//  pFunctionParameters		 - Array	 - Array of function parametrs (Array)
//  pBackgroundJobKey		 - UUID		 - UUID
//  pBacgroundJobName		 - String	 - If Undefined Job Name = Function Name (String)
//  pTempStorageAddress		 - String	 - Temporary storage address (String), if Undefined will generate address.
//  pTransactionActive		 - Boolean	 - Active
//  pTransactionUUID		 - UUID		 - UUID
//  pTransactionStartTime	 - Date		 - Date
// 
// Returns:
//  Structure - {UUID, TempStorageAddress}
//
Function StartBackgroundJobWithRecordInRegister(pObjectRef, pOperationName, pFunctionName, pFunctionParameters = Undefined, pBackgroundJobKey = Undefined, pBacgroundJobName = Undefined, pTempStorageAddress = Undefined, pTransactionActive = Undefined, pTransactionUUID = Undefined, pTransactionStartTime = Undefined) Export
	CleanCompletedBackgroundOperationsInProgress();
	vBackgroundJob = BackgroundJobs.Execute(pFunctionName, pFunctionParameters, pBackgroundJobKey, ?(IsBlankString(pBacgroundJobName), pFunctionName, pBacgroundJobName));
	
	If pTempStorageAddress = Undefined Then
		pTempStorageAddress = PutToTempStorage(Null);
	EndIf;
	
	vRecordManager 					= InformationRegisters.BackgroundOperationsInProgress.CreateRecordManager();
	vRecordManager.Object 			= pObjectRef;
	vRecordManager.OperationUUID 	= vBackgroundJob.UUID;
	vRecordManager.Description 		= NStr(pOperationName);
	If pTransactionActive <> Undefined Then
		vRecordManager.TransactionActive = pTransactionActive;
	Else
		vRecordManager.TransactionActive = False;
	EndIf;
	If pTransactionUUID <> Undefined Then
		vRecordManager.TransactionUUID = pTransactionUUID;
	Else
		vRecordManager.TransactionUUID = Undefined;
	EndIf;
	If vRecordManager.TransactionActive Then
		If pTransactionStartTime <> Undefined Then
			vRecordManager.TransactionStartTime = pTransactionStartTime;
		Else
			vRecordManager.TransactionStartTime = CurrentSessionDate();
		EndIf;
	Else
		vRecordManager.TransactionStartTime = '00010101';
	EndIf;
	vRecordManager.Write();
	
	Result = New Structure;
	Result.Insert("UUID", vBackgroundJob.UUID);
	Result.Insert("TempStorageAddress", pTempStorageAddress);
	Return Result;
EndFunction //  StartBackgroundJob()

// --------------------------------------------------------------------------------
//  Function - Cancel background job
//
// Parameters:
//  pBackgroundJobID - UUID	 - UUID
// 
// Returns:
//  Boolean - cancel or no
//
Function CancelBackgroundJob(pBackgroundJobID) Export
	Try
	 	BackgroundJob = BackgroundJobs.FindByUUID(pBackgroundJobID);
		BackgroundJob.Cancel();
		vResult = True;
	Except
		vResult = False;	
	EndTry;
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Function - Check background job
//
// Parameters:
//  pBackgroundJobID		 - UUID	 - UUID
//  pDeleteReadedMessages	 - Boolean	 - DeleteReadedMessages
// 
// Returns:
//  Structure - {Status, Messages, Progress, Error}
//
Function CheckBackgroundJob(pBackgroundJobID, pDeleteReadedMessages = False) Export
	vResult = New Structure("Status, Messages, Progress, Error", "Processing", New Array, 0, Undefined);

	vBackgroundJob = BackgroundJobs.FindByUUID(pBackgroundJobID);
	
	If vBackgroundJob = Undefined Then
		vResult.Status = "NotExist";
		Return vResult;
	EndIf;
	
	If vBackgroundJob.State = BackgroundJobState.Canceled Then
		vResult.Status = "Canceled";
	ElsIf vBackgroundJob.State = BackgroundJobState.Failed Then
		vResult.Status 	= "Error";
		vResult.Error	= vBackgroundJob.ErrorInfo.Description;
	ElsIf vBackgroundJob.State = BackgroundJobState.Completed Then
		vResult.Status = "Completed";
	EndIf;
	
	vResult.Progress = GetBackgroundJobProgress(vBackgroundJob);
	vResult.Messages = GetBackgroundJobUserMessages(vBackgroundJob, pDeleteReadedMessages);
	
	Return vResult;

EndFunction //  CheckBackgroundJob()

// --------------------------------------------------------------------------------
//
// Parameters:
//  pBackgroundJob			 - UUID	 - UUID
//  pDeleteReadedMessages	 - Boolean	 - DeleteReadedMessages
// 
// Returns:
//  Array - Messages
//
Function GetBackgroundJobUserMessages(pBackgroundJob, pDeleteReadedMessages = False) Export
	vResult = New Array;
	
	vMessagesArray = pBackgroundJob.GetUserMessages(pDeleteReadedMessages);
	
	For each msg in vMessagesArray Do
		vNotTaggedMsg = True;
		
		If StrFind(msg.Text, "<message>") > 0 Then
			vStartPos 	= StrFind(msg.Text, "<message>") + 9;
			vEndPos 	= StrFind(msg.Text, "</message>");
			vResult.Add(Mid(msg.Text,vStartPos,vEndPos - vStartPos));
			vNotTaggedMsg = False;
		EndIf;
		
		If StrFind(msg.Text, "<progress>") > 0 Then
			vNotTaggedMsg = False;
		EndIf;
		
		If ValueIsFilled(msg.Text) And vNotTaggedMsg Then
			vResult.Add(msg.Text);	
		EndIf;
	EndDo;

	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pBackgroundJob	 - UUID	- UUID
// 
// Returns:
//  String - Progress
//
Function GetBackgroundJobProgress(pBackgroundJob) Export
	vResult = "";
	vMessagesArray = pBackgroundJob.GetUserMessages(False);
	
	For Each msg In vMessagesArray Do		
		If StrFind(msg.Text, "<progress>") > 0 Then
			vStartPos 	= StrFind(msg.Text, "<progress>") + 10;
			vEndPos 	= StrFind(msg.Text, "</progress>");
			vResult 	= Mid(msg.Text, vStartPos, vEndPos - vStartPos);
		EndIf;
	EndDo;

	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Procedure - Clean completed background operations in progress
//  
//  Delete all records from register where background job status <> "Processing"
//
Procedure CleanCompletedBackgroundOperationsInProgress() Export
	vRecordSet	= InformationRegisters.BackgroundOperationsInProgress.CreateRecordSet();
	vRecordSet.Read();
	vDESTROYINGArray = New Array;
	For Each vRecord In vRecordSet Do
		If CheckBackgroundJob(vRecord.OperationUUID).Status <> "Processing" then
			vDESTROYINGArray.Add(vRecord.OperationUUID); 
		EndIf;
	EndDo;
	
	For Each vRow In vDESTROYINGArray Do
		vRecordSet	= InformationRegisters.BackgroundOperationsInProgress.CreateRecordSet();
		vRecordSet.Filter.OperationUUID.Set(vRow);
		vRecordSet.Write();
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
//  Function - Check for existing background jobs in register
//
// Parameters:
//  pRef - String	 - Ref
// 
// Returns:
//  Array - of UUIDs
//
Function CheckForExistingBackgroundJobsInRegister(pRef) Export
	CleanCompletedBackgroundOperationsInProgress();
	vRecordSet	= InformationRegisters.BackgroundOperationsInProgress.CreateRecordSet();
	vRecordSet.Filter.Object.Set(pRef);
	vRecordSet.Read();
	vResult = New Array;
	For Each vRecord In vRecordSet Do
		vResult.Add(vRecord.OperationUUID); 
	EndDo;
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Procedure - Wait for background job
//
// Parameters:
//  pBackgroundJobID - UUID - UUID
//
Procedure WaitForBackgroundJob(pBackgroundJobID) Export
	BackgroundJobs.FindByUUID(pBackgroundJobID).WaitForCompletion();
EndProcedure

// --------------------------------------------------------------------------------
//  Procedure - Wait for array of background jobs
//
// Parameters:
//  pArrayOfBackgroundJobIDs - Array - Array of UUIDs
//
Procedure WaitForArrayOfBackgroundJobs(pArrayOfBackgroundJobIDs) Export
	vArrayOfBackgroundJobs = New Array;
	For Each vID In pArrayOfBackgroundJobIDs Do
		vArrayOfBackgroundJobs.Add(BackgroundJobs.FindByUUID(vID));
	EndDo;
	BackgroundJobs.WaitForCompletion(vArrayOfBackgroundJobs);
EndProcedure

#EndRegion
