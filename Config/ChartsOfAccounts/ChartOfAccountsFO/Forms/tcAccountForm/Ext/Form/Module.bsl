// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.Hotel) Then
			Object.Hotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure BreakDownListSettingsVariableValueOnChange(pItem)
	vCurData = Items.PostingsListSettings.CurrentData;
	If ValueIsFilled(vCurData.Variable) Then
		vCurData.Symbol	= TrimAll(tcOnServer.cmGetAttributeByRef(vCurData.Variable, "Code"));
		vCurData.Formula = TrimAll(tcOnServer.cmGetAttributeByRef(vCurData.Variable, "Formula"));
		BreakDownListSettingsVariableNameOnChange(Items.BreakDownListSettingsVariableName)
	EndIf;
EndProcedure // BreakDownListSettingsVariableValueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BreakDownListSettingsVariableNameOnChange(pItem)
	vCurData = Items.PostingsListSettings.CurrentData;
	If vCurData <> Undefined Then
		If Not IsBlankString(vCurData.Symbol) Then
			vCurData.Symbol = tcCommonFunctionOnClientServer.GetFormulaSymbolName(vCurData.Symbol);
		EndIf;
	EndIf;
EndProcedure // BreakDownListSettingsVariableNameOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BreakDownListSettingsAccountOnChange(pItem)
	vCurData = Items.PostingsListSettings.CurrentData;
	If vCurData <> Undefined Then
		vAccount = vCurData.Account;
		If ValueIsFilled(vAccount) Then
			vAccountType = tcOnServer.cmGetAttributeByRef(vAccount, "Type");
			If vAccountType = AccountType.Active Then
				vCurData.Sign = PredefinedValue("Enum.AccountSigns.Dt");
			ElsIf vAccountType = AccountType.Passive Then
				vCurData.Sign = PredefinedValue("Enum.AccountSigns.Cr");
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BreakDownListSettingsAccountOnChange
