// --------------------------------------------------------------------------------
&AtClient
Procedure ValueSymbolOnChange(pItem)
	If Not IsBlankString(Object.ValueSymbol) Then
		Object.ValueSymbol = tcCommonFunctionOnClientServer.GetFormulaSymbolName(Object.ValueSymbol);
	EndIf;
EndProcedure // ValueSymbolOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure CodeOnChange(pItem)
	If Not IsBlankString(Object.Code) Then
		Object.Code = tcCommonFunctionOnClientServer.GetFormulaSymbolName(Object.Code);
	EndIf;
EndProcedure // CodeOnChange
