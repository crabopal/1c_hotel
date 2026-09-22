
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Items.DecorationMessage.Title = Parameters.MessageText;   
	
	If Parameters.DoProcessing Then       
		Items.FormContinue.Visible = False;	
		Items.FormClose.Visible = False;
	Else	
		Items.FormContinue.Visible = Parameters.ButtonContinue;
		
		If Parameters.ButtonContinue = False And Parameters.ButtonExit = False And Not IsBlankString(Parameters.MessageText) Then 
			Items.FormContinue.Visible = True;
		ElsIf IsBlankString(Parameters.MessageText) Then
			pCancel = True;
		EndIf;	
		If Parameters.ButtonExit Then
			Items.FormClose.Visible = Parameters.ButtonExit;
			Items.FormClose.DefaultButton = True;
		EndIf;   
		If Parameters.Property("TimeToClose") Then
			TimeToClose = Parameters.TimeToClose;
		EndIf;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Parameters.ButtonExit Then
		 Terminate();
	EndIf; 
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "InfoBaseUpdate.Done" Then 
		Close();
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If TimeToClose > 0 Then
	   AttachIdleHandler("CloseByTimeout", 0.1, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure fmClose(Command)
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseByTimeout()  
	tcOnServer.Wait(TimeToClose);
	Terminate();	
EndProcedure

#EndRegion
