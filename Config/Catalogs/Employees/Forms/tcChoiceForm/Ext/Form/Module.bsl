
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then    
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);    
		vArray.Add(Catalogs.Hotels.EmptyRef());    
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;
	vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.EmployeesFolder) Then
		Parameters.Filter.Insert("Parent", vPermGrp.EmployeesFolder);
		Items.List.TopLevelParent = vPermGrp.EmployeesFolder;
	EndIf;
	If Parameters.Property("MultipleChoice") And Parameters.MultipleChoice <> Undefined Then
		If TypeOf(Parameters.MultipleChoice) = Type("Boolean") And Parameters.MultipleChoice Then
			CloseOnChoice = False;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
