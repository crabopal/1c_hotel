
#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If Not CheckUserPermission() Then
		Raise NStr("en='You do not have rights to this function!';ru='Нет прав на эту функцию!';de='Sie haben keine Rechte für diese Funktion!'");
	EndIf;
	OpenForm("Document.CloseOfPeriod.ListForm", , pCommandExecuteParameters.Source, "tcCloseOfPeriodsForm", GetMainWindow());
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// 
// Returns:
//  Boolean - have user permission
//
&AtServer
Function CheckUserPermission()
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If Not ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckUserPermission

// -------------------------------------------------------------------------
// 
// Returns:
//  MainWindow - Main window
//
&AtClient
Function GetMainWindow()
	vWindows = GetWindows();
	vMainWindow = Undefined;
	For Each vWindow In vWindows Do
		If vWindow.IsMain Then
			vMainWindow = vWindow;
			Break;
		EndIf;
	EndDo;
	Return vMainWindow;
EndFunction // GetMainWindow

#EndRegion
