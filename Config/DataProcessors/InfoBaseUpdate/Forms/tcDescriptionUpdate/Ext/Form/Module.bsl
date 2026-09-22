
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	fmGenerate();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure fmGenerate()
	vTemplate = DataProcessors.InfoBaseUpdate.GetTemplate("DescriptionUpdate");
	vList = New ValueList;
	For Each vInt In vTemplate.Areas Do
		If Left(vInt.Name, 7) = "Version" Then
			vList.Add(Right(vInt.Name, 6));	
		EndIf;
	EndDo;
	vList.SortByValue(SortDirection.Desc);
	vSpreadsheetDocument = New SpreadsheetDocument;
	IsFirst = True;
	For Each vInt In vList Do
		vVersion = vInt.Value;
		If IsFirst Then
			Try
				vSpreadsheetDocument.Put(vTemplate.GetArea("Head" + vVersion));
				vSpreadsheetDocument.Put(vTemplate.GetArea("Version" + vVersion));
				vSpreadsheetDocument.Put(vTemplate.GetArea("Indent"));
			Except
			EndTry;
			IsFirst = False;
		Else
			Try
				vSpreadsheetDocument.Put(vTemplate.GetArea("Head" + vVersion));
				vSpreadsheetDocument.StartRowGroup("Version" + vVersion, False);
				vSpreadsheetDocument.Put(vTemplate.GetArea("Version" + vVersion));
				vSpreadsheetDocument.EndRowGroup();
				vSpreadsheetDocument.Put(vTemplate.GetArea("Indent"));
			Except
			EndTry;
		EndIf;
	EndDo;
	SpreadsheetDocument = vSpreadsheetDocument;
EndProcedure

#EndRegion 
