
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vScheduledJobKey = Undefined;
	vDP = Undefined;
	
	If Parameters.Property("ScheduledJobKey") Then
		vScheduledJobKey = Parameters.ScheduledJobKey; 
	EndIf;
	
	If Parameters.Property("DataProcessor") Then
		vDP = Parameters.DataProcessor; 
	EndIf;
	
	If Not (Parameters.Property("ScheduledJobKey") And ValueIsFilled(Parameters.ScheduledJobKey))
		And Not (Parameters.Property("DataProcessor") And ValueIsFilled(Parameters.DataProcessor)) Then
		
		Raise Nstr("en = 'Do not set key or dataprocessor'; de = 'Do not set key or dataprocessor'; ru = 'Не передан ключ или ссылка на обработку'");
		
	EndIf;	
	
	For Each vScheduledJob In Metadata.ScheduledJobs Do
		Items.MetadataChoice.ChoiceList.Add(vScheduledJob.Name, vScheduledJob.Presentation());
	EndDo;
	
	If ValueIsFilled(vScheduledJobKey) Or ValueIsFilled(vDP) Then
		SetScheduledJob(vScheduledJobKey, vDP);
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Do not set key or dataprocessor'; de = 'Do not set key or dataprocessor'; ru = 'Не передан ключ или ссылка на обработку'"));
		Cancel = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Use = False Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Key"));
		CheckedAttributes.Delete(CheckedAttributes.Find("Employee"));
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	#If NOT MobileClient Then
		vScheduleDlg = New ScheduledJobDialog(Schedule);
		vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisObject, New Structure()));
	#Else
	 	ShowMessageBox(,"Background job cant be configured on mobile client!");
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	ClearMessages();
	SaveAtServer();
	Close();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAtServer()
	If CheckFilling() Then
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			vScheduledJob = ArrayScheduledJob[0];
			SetScheduledJobParameters(vScheduledJob);
		EndIf;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetScheduledJob(pKey = Undefined, pDataProcessor = Undefined)
	Try
		
		If Not pKey = Undefined Then
			Key = pKey;
			// Fill by key
			ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Key));
			
			If ArrayScheduledJob.Count() > 0 Then
				vScheduledJob = ArrayScheduledJob[0];
				
				FillHeaderObject(vScheduledJob);
				
			EndIf;	
		ElsIf Not pDataProcessor = Undefined Then
			// Fill by dataprocessor
			Key = GetKeyBackgroundJob(pDataProcessor);
			
			// Set description
			Description = Nstr(pDataProcessor.Description);
			If IsBlankString(Description) And Not IsBlankString(pDataProcessor.Description) Then
				Description = pDataProcessor.Description;
			EndIf;	
			
			ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Key));
			
			If ArrayScheduledJob.Count() > 0 Then
				vScheduledJob = ArrayScheduledJob[0];
				
				FillHeaderObject(vScheduledJob);

			Else
				For Each vSJob In Metadata.ScheduledJobs Do   
					If vSJob.Name = "RunDataProcessor" Then
						vScheduledJob = ScheduledJobs.CreateScheduledJob(vSJob);
						Break;
					EndIf;
				EndDo;
				
				SetScheduledJobParameters(vScheduledJob);
				
				FillHeaderObject(vScheduledJob);
			EndIf;	
		Else
			Raise Nstr("en = 'Do not set key or dataprocessor'; de = 'Do not set key or dataprocessor'; ru = 'Не передан ключ или ссылка на обработку'");
		EndIf;	
		
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetScheduledJobParameters(vScheduledJob)
	If Schedule = Undefined Then
		// Is new
		vScheduledJob.Description 				= Description;
		vScheduledJob.Key 						= Key;
		vScheduledJob.Use 						= Use;
	Else	
		// Save settings
		vScheduledJob.Description 				= Description;
		vScheduledJob.Key 						= Key;
		vScheduledJob.Use 						= Use;
		vScheduledJob.UserName 					= Employee;
		vScheduledJob.RestartCountOnFailure 	= RestartCountOnFailure;
		vScheduledJob.RestartIntervalOnFailure 	= RestartIntervalOnFailure;
		vScheduledJob.Schedule 					= Schedule;
	EndIf;
	
	If vScheduledJob.Parameters.Count() = 0 Then
		vScheduledJob.Parameters.Add(Key);
	EndIf;
	
	vScheduledJob.Write();

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillHeaderObject(pScheduledJob)
	Description 				= pScheduledJob.Description;
	Employee  					= Catalogs.Employees.FindByDescription(pScheduledJob.UserName);
	Schedule  					= pScheduledJob.Schedule;
	Use  						= pScheduledJob.Use;	
	Key 						= pScheduledJob.Key;
	RestartCountOnFailure 		= pScheduledJob.RestartCountOnFailure;
	RestartIntervalOnFailure 	= pScheduledJob.RestartIntervalOnFailure;
	MetadataChoice				= pScheduledJob.Metadata.Name;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		Schedule = pValue;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetKeyBackgroundJob(pDataProcessor)
	vDPKey = pDataProcessor.Key;
	If IsBlankString(vDPKey) Then
		// Add new unique key
		vKey = String(New UUID());
		vObj = pDataProcessor.GetObject();
		vObj.Key = vKey;
		vObj.Write();
	Else
		vKey = TrimAll(vDPKey);
	EndIf;
	
	Return vKey;
EndFunction

#EndRegion    
