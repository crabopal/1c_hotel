// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	If Ref <> ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
		If Not ValueIsFilled(AccountType) Then
			pCancel = True;
			Raise NStr("en='Account type should be filled!'; ru='Тип счета должен быть заполнен!'; de='Der Kontotyp muss ausgefüllt werden!'");
		EndIf;
	EndIf;
	Order = TrimAll(Code);
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite