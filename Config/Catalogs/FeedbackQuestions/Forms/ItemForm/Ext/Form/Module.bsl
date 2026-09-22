
#Region Form_events

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SetFormItemsVisibility();
	If Object.AnswerNumberRestrictionTo = 0 Then
		Object.AnswerNumberRestrictionTo = 9999999;
	EndIf;
	If Object.AnswerNumberRestrictionFrom = 0 Then
		Object.AnswerNumberRestrictionTo = 1;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)	
	If NOT CheckAnswerNumberRestrictionTo(Object.AnswerType, Object.AnswerNumberRestrictionTo) Then
		vMessage = New UserMessage;
		vMessage.SetData(Object.AnswerNumberRestrictionTo);
		vMessage.Text = NStr("en = 'Specify the maximum range for a numerical answer.'; ru = 'Укажите максимальный диапазон числового ответа.'; de = 'Geben Sie den maximalen Bereich für eine numerische Antwort an.'");
		vMessage.Message();
		pCancel = True;
	EndIf;
	
	If Object.AnswerType = PredefinedValue("Enum.AnswerTypes.List") Then
		If Object.AnswerListMaxVariants <> 1 Then
			For each vRow in Object.AnswerVariants Do
				vRow.AnswerWeight = 0;
			EndDo;
		EndIf;
	Else
		Object.AnswerVariants.Clear();	
	EndIf;
	
EndProcedure

#EndRegion

#Region Form_items_events

&AtClient
Procedure AnswerTypeOnChange(pItem)
	SetFormItemsVisibility();
EndProcedure

&AtClient
Procedure AnswerListMaxVariantsOnChange(pItem)
	SetFormItemsVisibility();
EndProcedure

#EndRegion

&AtServer
Procedure SetFormItemsVisibility()
	If Object.AnswerType = Enums.AnswerTypes.List Then
		Items.Group_List.Visible = True;
		If Object.AnswerListMaxVariants = 1 Then
			Items.AnswerVariantsAnswerWeight.Visible = True;
		Else
			Items.AnswerVariantsAnswerWeight.Visible = False;
		EndIf;
	Else
		Items.Group_List.Visible = False;
	EndIf;
	If Object.AnswerType = Enums.AnswerTypes.Number Then
		Items.Group_AnswerNumberRestrictions.Visible = True;
	Else
		Items.Group_AnswerNumberRestrictions.Visible = False;
	EndIf;
EndProcedure

&AtServerNoContext
Function CheckAnswerNumberRestrictionTo(pAnswerType, pAnswerNumberRestrictionTo)
	vResult = True;
	If pAnswerType = Enums.AnswerTypes.Number and pAnswerNumberRestrictionTo = 0 Then
		vResult = False;
	EndIf;
	Return vResult
EndFunction

&AtClient
Procedure AnswerNumberRestrictionToOnChange(pItem)
	If Object.AnswerNumberRestrictionTo < 2 Then
		Object.AnswerNumberRestrictionTo = 2;
		vMessage = New UserMessage;
		vMessage.SetData(Object.AnswerNumberRestrictionTo);
		vMessage.Text = NStr("en = 'The maximum range of a numerical response can not be less than 2!'; de = 'Der maximale Bereich einer numerischen Antwort darf nicht kleiner als 2 sein!'; ru = 'Максимальный диапазон числового ответа не может быть меньше 2!'");
		vMessage.Message();
	EndIf;
EndProcedure

&AtClient
Procedure AnswerNumberRestrictionFromOnChange(Item)
	If Object.AnswerNumberRestrictionFrom < 1 Then
		Object.AnswerNumberRestrictionFrom = 1;
		vMessage = New UserMessage;
		vMessage.SetData(Object.AnswerNumberRestrictionFrom);
		vMessage.Text = NStr("en = 'The minimum range of a numerical response can not be less than 1!'; de = 'Der minimale Bereich einer numerischen Antwort darf nicht kleiner als 1 sein!'; ru = 'Минимальный диапазон числового ответа не может быть меньше 1!'");
		vMessage.Message();
	EndIf;
EndProcedure

