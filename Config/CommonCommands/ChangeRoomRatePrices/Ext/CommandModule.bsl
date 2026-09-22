
#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If Not CheckUserPermission() Then
		Raise NStr("en='You do not have rights to this function!';ru='Нет прав на эту функцию!';de='Sie haben keine Rechte für diese Funktion!'");
	EndIf;
	#If Not WebClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 40, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
	#EndIf
	OpenForm("CommonForm.tcChangeRoomRatesWizard", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window);
	#If Not WebClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 100, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
	#EndIf
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

#EndRegion
