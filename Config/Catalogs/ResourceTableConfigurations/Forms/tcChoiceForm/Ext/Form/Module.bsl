// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Resource") And ValueIsFilled(Parameters.Resource) Then
		If Parameters.Resource.TableConfigurationsAllowed.Count() > 0 Then
			vAllowedRefsList = New ValueList();
			For Each vATCRow In Parameters.Resource.TableConfigurationsAllowed Do
				If ValueIsFilled(vATCRow.ResourceTableConfiguration) And Not vATCRow.ResourceTableConfiguration.DeletionMark Then
					If vAllowedRefsList.FindByValue(vATCRow.ResourceTableConfiguration) = Undefined Then
						vAllowedRefsList.Add(vATCRow.ResourceTableConfiguration);
					EndIf;
				EndIf;
			EndDo;
			If vAllowedRefsList.Count() > 0 Then
				tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Ref", vAllowedRefsList, DataCompositionComparisonType.InList, , True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
