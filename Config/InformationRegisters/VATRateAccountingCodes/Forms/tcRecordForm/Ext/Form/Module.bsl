// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Record.Hotel) And Not ValueIsFilled(Record.Company) And IsBlankString(Record.Code) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Record");
	If Not ValueIsFilled(pCurrentObject.Account) And IsBlankString(pCurrentObject.Code) Then
		pCancel = True;
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "Code";
		vUM.Text = NStr("en='Please fill account or text code!'; ru='Укажите счет или код счета!'; de='Geben Sie das Konto oder Kontocode!'");
		vUM.Message();
	EndIf;
EndProcedure // BeforeWriteAtServer
