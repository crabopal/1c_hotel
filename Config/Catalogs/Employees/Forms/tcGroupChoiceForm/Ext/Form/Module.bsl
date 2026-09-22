// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.EmployeesFolder) Then
		Items.List.TopLevelParent = vPermGrp.EmployeesFolder;
		Items.Tree.TopLevelParent = vPermGrp.EmployeesFolder;
	EndIf;
EndProcedure
