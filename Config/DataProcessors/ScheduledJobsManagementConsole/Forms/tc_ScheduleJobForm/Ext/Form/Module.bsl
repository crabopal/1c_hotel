
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelUUID") Then
		ScheduledUUID = Parameters.SelUUID;	
	EndIf;
	
	If Parameters.Property("SelIsCopy") Then
		IsCopy = Parameters.SelIsCopy;	
	EndIf;
	
	If Parameters.Property("SelLastJobUUID") Then
		LastJobUUID = Parameters.SelLastJobUUID;
	EndIf;
	
	If ValueIsFilled(LastJobUUID) Then 
		vLastJob = BackgroundJobs.FindByUUID(LastJobUUID);
		If vLastJob <> Undefined Then
			Items.GroupLastJob.Visible = True;
			State = TrimAll(vLastJob.State);
			Begin = vLastJob.Begin;
			End = vLastJob.End;
			vMessegJob = AsyncCalls.GetBackgroundJobUserMessages(vLastJob);
			UserMessagesAndErrorDetails = "";
			If vLastJob.ErrorInfo <> Undefined Then
				UserMessagesAndErrorDetails = vLastJob.ErrorInfo.Description + Chars.LF;
			EndIf;
			For Each vMsg In vMessegJob Do
				UserMessagesAndErrorDetails = UserMessagesAndErrorDetails + vMsg + Chars.LF;	
			EndDo;
		EndIf;
	EndIf;
	
	If IsCopy Then
		Title = Title + NStr("en = ' - copy'; de = ' - Kopie'; ru = ' - копия'"); 	
	EndIf;
	
	For Each vScheduledJob In Metadata.ScheduledJobs Do
		Items.MetadataChoice.ChoiceList.Add(TrimAll(vScheduledJob.Name), vScheduledJob.Presentation());
	EndDo;
	
	Try
		vUsers = InfoBaseUsers.GetUsers();
	    For Each vUser In vUsers Do
			Items.UsersChoice.ChoiceList.Add(TrimAll(vUser.Name), vUser.FullName);
		EndDo;
	Except
	EndTry;
	
	If ValueIsFilled(ScheduledUUID) Then
		vScheduledJob = ScheduledJobs.FindByUUID(ScheduledUUID);
		MetadataChoice = TrimAll(vScheduledJob.Metadata.Name);
		Items.MetadataChoice.Enabled = False;
		Description = vScheduledJob.Description;
		Key = vScheduledJob.Key;
		Use = vScheduledJob.Use;
		UsersChoice = TrimAll(vScheduledJob.UserName);
		RestartCountOnFailure = vScheduledJob.RestartCountOnFailure;
		RestartIntervalOnFailure = vScheduledJob.RestartIntervalOnFailure;
		Schedule = vScheduledJob.Schedule;
	Else
		Schedule = New JobSchedule;
	EndIf;
	WindowOptionsKey = UUID;
EndProcedure // OnCreateAtServer 

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	vScheduledJobDialog = New ScheduledJobDialog(Schedule);
	vScheduledJobDialog.Show(New NotifyDescription("OpenScheduleCompletion", ThisObject));
EndProcedure // SetupBackgroundJobSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	SaveAtServer();
	Close(ScheduledUUID);
EndProcedure // Save

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAtServer()
	Try
		If MetadataChoice = Undefined Then
			Raise(NStr("en='Scheduled job metadata is not selected!';ru='Не выбраны метаданные регламентного задания!';de='Keine Metadaten der Wartungsaufgabe sind gewählt!'"));
		EndIf;
		
		If Not ValueIsFilled(ScheduledUUID) Or IsCopy Then
			vScheduledJob = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs[MetadataChoice]);
		Else
			vScheduledJob = ScheduledJobs.FindByUUID(ScheduledUUID);
		EndIf;
		ScheduledUUID = vScheduledJob.UUID; 
		vScheduledJob.Description = Description;
		vScheduledJob.Key = TrimAll(Key);
		vScheduledJob.Use = Use;
		vScheduledJob.UserName = UsersChoice;
		vScheduledJob.RestartCountOnFailure = RestartCountOnFailure;
		vScheduledJob.RestartIntervalOnFailure = RestartIntervalOnFailure;
		vScheduledJob.Schedule = Schedule;
		// Set parameters
		If MetadataChoice = Metadata.ScheduledJobs.RunDataProcessor.Name Or 
		   MetadataChoice = Metadata.ScheduledJobs.GenerateReport.Name Then
			vParmArray = New Array();
			vParmArray.Add(vScheduledJob.Key);
			vScheduledJob.Parameters = vParmArray;
		EndIf;
		// Write
		vScheduledJob.Write();
		
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());	
	EndTry;
EndProcedure // SaveAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenScheduleCompletion(pNewSchedule, pExtraParams) Export
	If pNewSchedule <> Undefined Then
		Schedule = pNewSchedule;
	EndIf;
EndProcedure // OpenScheduleCompletion

#EndRegion    
