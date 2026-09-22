
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Name") Then
		If Parameters.Name = "AccommodationType" Or Parameters.Name = "AccommodationTypeExcluding" Then
			If Parameters.Name = "AccommodationTypeExcluding" Then
				Excluding = True;	
			EndIf;
			Title = NStr("en='Mark the accommodation types'; ru='Отметьте виды размещения'; de='Markieren Sie die Unterbringungentypen'");
			vQry = New Query;
			vQry.Text = 
			"SELECT
			|	AccommodationTypes.Ref AS Ref
			|FROM
			|	Catalog.AccommodationTypes AS AccommodationTypes
			|WHERE
			|	NOT AccommodationTypes.DeletionMark
			|
			|ORDER BY
			|	AccommodationTypes.SortCode,
			|	AccommodationTypes.Code";
			vRes = vQry.Execute().Unload();
			For Each vStr In vRes Do
				vNewStr = ToChoose.Add();
				vNewStr.Type = vStr.Ref;
			EndDo;
		ElsIf Parameters.Name = "RoomType" Or Parameters.Name = "RoomTypeExcluding" Then
			If Parameters.Name = "RoomTypeExcluding" Then
				Excluding = True;	
			EndIf;
			Title = NStr("en='Mark the room types'; ru='Отметьте типы номеров'; de='Markieren Sie die Zimmertypen'");
			vQry = New Query;
			vQry.Text = 
			"SELECT
			|	RoomTypes.Ref AS Ref
			|FROM
			|	Catalog.RoomTypes AS RoomTypes
			|WHERE
			|	NOT RoomTypes.DeletionMark
			|
			|ORDER BY
			|	RoomTypes.SortCode,
			|	RoomTypes.Code";
			vRes = vQry.Execute().Unload();
			For Each vStr In vRes Do
				vNewStr = ToChoose.Add();
				vNewStr.Type = vStr.Ref;
			EndDo;					
		ElsIf Parameters.Name = "RoomClass" Or Parameters.Name = "RoomClassExcluding" Then
			If Parameters.Name = "RoomClassExcluding" Then
				Excluding = True;	
			EndIf;
			Title = NStr("en='Mark the room type classes'; ru='Отметьте классы номера'; de='Markieren Sie die Zimmertypklassen'");
			vQry = New Query;
			vQry.Text = 
			"SELECT
			|	RoomTypeClasses.Ref AS Ref
			|FROM
			|	Catalog.RoomTypeClasses AS RoomTypeClasses
			|WHERE
			|	NOT RoomTypeClasses.DeletionMark
			|
			|ORDER BY
			|	RoomTypeClasses.SortCode,
			|	RoomTypeClasses.Code";
			vRes = vQry.Execute().Unload();
			For Each vStr In vRes Do
				vNewStr = ToChoose.Add();
				vNewStr.Type = vStr.Ref;
			EndDo;
		EndIf;
		If Parameters.Property("List") Then
			If Parameters.List.Count() > 0 Then
				For Each vRow In Parameters.List Do 
					For Each vvRow In ToChoose Do
						If vRow = vvRow.Type Then
							vvRow.IsChecked = True;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Choose(pCommand)
	vValueList = New ValueList;
	For Each vRow In ToChoose Do
		If vRow.IsChecked Then
			vValueList.Add(vRow.Type);
		EndIf;
	EndDo;
	If Excluding And vValueList.Count() > 1 Then
		vValueList.Clear();
		For Each vRow In ToChoose Do
			If Not vRow.IsChecked Then
				vValueList.Add(vRow.Type);
			EndIf;
		EndDo;
	EndIf;
	Close(vValueList); 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAll(pCommand)
	For Each vRow In ToChoose Do
		vRow.IsChecked = True;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UnselectAll(pCommand)
	For Each vRow In ToChoose Do
		vRow.IsChecked = False;
	EndDo;
EndProcedure

#EndRegion
