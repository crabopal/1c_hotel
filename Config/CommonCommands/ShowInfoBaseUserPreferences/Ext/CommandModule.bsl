
#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vEmployee = tcOnServer.cmGetCurrentUserAttribute();   
	If Not tcOnServer.cmGetAttributeByRef(vEmployee, "AllowAccessToSystem") Then
		vMessage = NStr("en = 'The employee must be allowed access to the system! Please ask system administrator to check employee parameters in Settings menue.'; 
						|de = 'Der Mitarbeiter muss Zugang zum System haben! Bitte Fragen Sie Systemadministrator, mitarbeiterparameter im Einstellungsmenü zu überprüfen.'; 
						|ru = 'У сотрудника должен быть разрешен доступ в систему! Пожалуйста, попросите системного администратора проверить параметры сотрудника в меню настроек.'");
		ShowMessageBox(, vMessage);
	Else
		OpenForm("Catalog.Employees.Form.InfobaseUserSettings", New Structure("Employee", vEmployee));
	EndIf;
EndProcedure // CommandProcessing

#EndRegion
