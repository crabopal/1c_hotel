
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If IsNew() Then
			Raise NStr("en='You do not have rights to manage prices!'; ru='У вас нет прав управлять ценами!'; de='Sie besitzen keine Rechte zur Preisverwaltung!'");
		Else
			If IsFolder Then
				If Ref.DeletionMark <> DeletionMark Or 
				   Ref.Code <> Code Or Ref.Description <> Description Or
				   Ref.Hotel <> Hotel Or Ref.Parent <> Parent Then
					pCancel = True;
					Raise NStr("en='You do not have rights to manage prices!'; ru='У вас нет прав управлять ценами!'; de='Sie besitzen keine Rechte zur Preisverwaltung!'");
				EndIf;
			Else
				If Ref.DeletionMark <> DeletionMark Or 
				   Ref.Code <> Code Or Ref.Description <> Description Or
				   Ref.Hotel <> Hotel Or Ref.Parent <> Parent Or 
				   Ref.Remarks <> Remarks Or Ref.SortCode <> SortCode Then
					pCancel = True;
					Raise NStr("en='You do not have rights to manage prices!'; ru='У вас нет прав управлять ценами!'; de='Sie besitzen keine Rechte zur Preisverwaltung!'");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

#EndRegion
