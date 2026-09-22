
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Source") and Parameters.Property("FormName") Then
		//
		OpeningFormName = Parameters.FormName;
		WriteLogEvent("PreOpenForm_OnCreate", EventLogLevel.Warning,,CurrentSessionDate(),"Source: " + Parameters.Source + "; FormName: " + OpeningFormName );
		pCancel = False;
	Else
		WriteLogEvent("PreOpenForm_OnCreate", EventLogLevel.Error,,CurrentSessionDate(),"Failed to create PreOpenForm: FormName or Source parameter is missing!");
		pCancel = True;
	EndIf;
	If Parameters.Property("ObjectType") and Parameters.Property("ObjectName") and Parameters.Property("ObjectUUID") Then
		WriteLogEvent("PreOpenForm_OnCreate_ObjectReading", EventLogLevel.Warning,,CurrentSessionDate(),"ObjectType: " + Parameters.ObjectType + "; ObjectName: " + Parameters.ObjectName + "; ObjectUUID: " + Parameters.ObjectUUID);
		If ValueIsFilled(Parameters.ObjectType) and ValueIsFilled(Parameters.ObjectName) and ValueIsFilled(Parameters.ObjectUUID) Then
			Try
				If Parameters.ObjectType = "Document" Then
					Ref = Documents[Parameters.ObjectName].GetRef(New UUID(Parameters.ObjectUUID));
				ElsIf Parameters.ObjectType = "Catalog" Then
					Ref = Catalogs[Parameters.ObjectName].GetRef(New UUID(Parameters.ObjectUUID));
				EndIf;
				pCancel = False;
			Except
				vError = ErrorDescription();
				tcCommonFunctionOnClientServer.TextMessage(vError);
				WriteLogEvent("PreOpenForm_OnCreate_ObjectReading", EventLogLevel.Error,,CurrentSessionDate(), "Failed to create PreOpenForm: " + vError);
				pCancel = True;
			EndTry;	
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	#IF NOT MobileClient THEN
		Try
			WSHShell = New COMObject("WScript.Shell");
			WSHShell.SendKeys("%+(R)");
		Except
		EndTry;
	#ENDIF
	Try
		If ValueIsFilled(Ref) Then 
			OpenForm(OpeningFormName, New Structure("Key", Ref));
		Else
			OpenForm(OpeningFormName);
		EndIf;
	Except
		vError = ErrorDescription();
		WriteLog(vError);
	EndTry;
	ThisForm.Close();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteLog(pError)
	WriteLogEvent("PreOpenForm_OnOpen", EventLogLevel.Error,,CurrentSessionDate(), "Failed to open form: " + pError);
EndProcedure

#EndRegion
