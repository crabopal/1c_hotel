// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		If ValueIsFilled(Object.Ref) Then
			ThisObject.ReadOnly = True;
		Else
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
