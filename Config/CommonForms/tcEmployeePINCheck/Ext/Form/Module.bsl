
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	CurrentEmployee = SessionParameters.CurrentUser;
	ModeAfterCheck = Parameters.ModeAfterCheck;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

 // --------------------------------------------------------------------------------
&AtClient
Procedure CheckPINCode(pCommand)
	If Not IsBlankString(PINCode) Then
		If CheckPINCodeAtServer() Then
			AttachIdleHandler("Attachable_CloseThisForm", 0.5, True);
		Else
			vUM = New UserMessage();
			vUM.Field = "PINCode";
			vUM.Text = NStr("en='PIN code is wrong!'; ru='ПИН-код указан неверно!'; de='PIN-Code ist falsch!'");
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure // CheckPINCode

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
&AtClient
Procedure Attachable_CloseThisForm() Export
	If ThisForm.IsOpen() Then
		ThisForm.Close();
		Notify("SessionParameters.CurrentUser.Change", New Structure("Employee, ModeAfterCheck", CurrentEmployee, ModeAfterCheck));
	EndIf;
EndProcedure // CloseThisForm

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function CheckPINCodeAtServer()
	vResult = tcOnServer.CheckEmployeePINCode(TrimAll(PINCode));
	If vResult Then
		CurrentEmployee = SessionParameters.CurrentUser;
	Else
		PINCode = "";
	EndIf;
	Return vResult;
EndFunction // CheckPINCodeAtServer

#EndRegion

