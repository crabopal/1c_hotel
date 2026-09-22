// --------------------------------------------------------------------------------
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
	
	If Parameters.Property("ParametersKeyCard") And TypeOf(Parameters.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(Object, Parameters.ParametersKeyCard);
	EndIf;
	
	If Parameters.Property("ParametersKeyCard") And TypeOf(Parameters.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(Object, Parameters.ParametersKeyCard);
	EndIf;       
	
	If Parameters.Property("PINCodeList") And Parameters.PINCodeList <> Undefined Then
		For Each vRow In Parameters.PINCodeList Do
			vNewRow = PINCodeList.Add();
			vNewRow.Room 			= Object.Room;  
			vNewRow.PINCode 		= vRow.keyboardPwd;
			vNewRow.CheckInDate 	= ToLocalTime('19700101' + Int((vRow.startDate / 1000)));
			vNewRow.CheckOutDate 	= ToLocalTime('19700101' + Int((vRow.endDate / 1000)));
			vNewRow.CreationDate 	= ToLocalTime('19700101' + Int((vRow.sendDate / 1000)));
		EndDo;
	EndIf;	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel				= Object.ExternalInteraction.Hotel;
	Active				= Object.ExternalInteraction.IsActive;
	Debug				= Object.ExternalInteraction.DebugMode;
	OAuth_ClientID		= Object.ExternalInteraction.OAuth_ClientID;
	OAuth_ClientSecret	= Object.ExternalInteraction.OAuth_ClientSecret;
	OAuth_AccessToken	= Object.ExternalInteraction.OAuth_AccessToken;
	OAuth_RefreshToken	= Object.ExternalInteraction.OAuth_RefreshToken;
	Login				= Object.ExternalInteraction.Login;
	Password			= Object.ExternalInteraction.Password;
	HttpServer			= Object.ExternalInteraction.HttpServer;
	HttpUseSsl			= Object.ExternalInteraction.HttpUseSsl;
	MaxLogLenght		= Object.ExternalInteraction.MaxLogLenght;    
	ActiveToDate		= Object.ExternalInteraction.SessionStartTime + Object.ExternalInteraction.SessionTimeout;
EndProcedure // LoadInteractionParameters
