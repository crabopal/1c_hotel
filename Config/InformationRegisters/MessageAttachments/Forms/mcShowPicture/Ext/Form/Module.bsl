
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Property("SelPicture") Or Not ValueIsFilled(Parameters.SelPicture) Then
		pCancel = False;	
	EndIf;    
	SelPicture = Parameters.SelPicture;
	If Parameters.Property("SelMessage") Then
		SelMessage = Parameters.SelMessage;
		If ValueIsFilled(SelMessage) Then
			Title = SelMessage;
		EndIf;
	EndIf;
	If Parameters.Property("SelPeriod") Then
		SelPeriod = Parameters.SelPeriod;	
	EndIf; 
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Delete(pCommand)
	DeleteAtServer(SelPeriod, SelMessage);
	Close(True);
EndProcedure // Delete

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DeleteAtServer(pPeriod, pMessage)
	vRecSet 							= InformationRegisters.MessageAttachments.CreateRecordSet();
	vRecSet.Filter.Message.Use			= True;
	vRecSet.Filter.Message.Value 		= pMessage;
	vRecSet.Filter.Period.Use			= True;
	vRecSet.Filter.Period.Value			= pPeriod;
	vRecSet.Read();
	vRecSet.Clear();
	vRecSet.Write(True);
EndProcedure // DeleteAtServer

#EndRegion
