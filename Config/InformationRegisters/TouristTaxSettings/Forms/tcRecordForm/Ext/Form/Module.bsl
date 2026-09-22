// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vIsNew = Not ValueIsFilled(Record.Hotel) Or Not ValueIsFilled(Record.Period);
	If Not ValueIsFilled(Record.Hotel) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Record.Period) Then
		Record.Period = BegOfDay(CurrentSessionDate());
	EndIf;
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If vIsNew Then
			pCancel = True;
		Else
			ThisObject.ReadOnly = True;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"), MessageStatus.Information);
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	// Check if there is No VAT VAT rate in the system
	If Not ThereIsNoVATVATRate() Then
		ShowQueryBox(New NotifyDescription("CreateNoVATVATRate", ThisObject), 
		             NStr("en='You need to setup <No VAT> VAT rate in the system for tourist tax to work properly. Setup it manually with <No VAT> flag ON or answer <Yes> to the next question. Do you want to create this VAT rate now automatically?'; 
		                  |ru='Для работы с туристическим налогом в программе должна быть создана ставка НДС <Без НДС>. Создайте ставку вручную с включенным флагом <Без НДС> или ответьте <Да> на следующий вопрос. Создать ставку <Без НДС> сейчас автоматически?'; 
		                  |de='Damit die Kurtaxe richtig funktioniert, müssen Sie im System einen Mehrwertsteuersatz <Keine Mehrwertsteuer> einrichten. Richten Sie ihn manuell mit der Markierung <Keine Mehrwertsteuer> ein oder beantworten Sie die nächste Frage mit <Ja>. Möchten Sie diesen Mehrwertsteuersatz jetzt automatisch erstellen?'"), 
		             QuestionDialogMode.YesNo);
		pCancel = True;
		Return;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
&AtServerNoContext
Function ThereIsNoVATVATRate() 
	vNoVAT = cmGetNoVATVATRate();
	If Not ValueIsFilled(vNoVAT) Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ThereIsNoVATVATRate

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateNoVATVATRate(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		CreateNoVATVATRateAtServer();
		ShowMessageBox(, NStr("en='<No VAT> rate was created! Save tourist tax setting again'; ru='Ставка <Без НДС> создана! Сохраните настройку туристического налога еще раз'; de='Es wurde ein <Keine MwSt>-Satz angelegt! Kurtaxen-Einstellung erneut speichern'"));
	EndIf;
EndProcedure // CreateNoVATVATRate

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure CreateNoVATVATRateAtServer()
	cmCreateNoVATVATRate();
EndProcedure // CreateNoVATVATRateAtServer
