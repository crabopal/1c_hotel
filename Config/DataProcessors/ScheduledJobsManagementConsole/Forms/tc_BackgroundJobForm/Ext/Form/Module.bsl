
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
		                        
	If Parameters.BackgroundJobProperties = Undefined Then
		Raise(NStr("en = 'Background job is not found.'"));
	Else
		BackgroundJobProperties = Parameters.BackgroundJobProperties;
		FillPropertyValues(ThisObject,Parameters.BackgroundJobProperties);
		ThisObject.BackgroundJobUUID 			= Parameters.BackgroundJobProperties.UUID;
		ThisObject.UserMessagesAndErrorDetails 	= Parameters.BackgroundJobProperties.ErrorInfo + Chars.LF + Parameters.BackgroundJobProperties.UserMessages;
	EndIf;
	
EndProcedure

#EndRegion
