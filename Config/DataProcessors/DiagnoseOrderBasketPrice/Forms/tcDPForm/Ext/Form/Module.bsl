#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Object.Hotel) And Not ValueIsFilled(Object.RoomRate) Then
		Object.RoomRate = Object.Hotel.RoomRate;
	EndIf;
	If Object.Adults = 0 Then
		Object.Adults = 1;
	EndIf;
	If Not ValueIsFilled(Object.CheckInDate) Then
		Object.CheckInDate = BegOfDay(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(Object.CheckOutDate) Then
		Object.CheckOutDate = Object.CheckInDate + 2 * 24 * 3600;
	EndIf;
	Summary = "";
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Diagnose(Command)
	DiagnoseAtServer();
EndProcedure

&AtClient
Procedure FillFromRoom(Command)
	FillFromRoomAtServer();
EndProcedure

#EndRegion

#Region FormItemsEventHandlers

&AtClient
Procedure RoomOnChange(Item)
	FillFromRoomAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillFromRoomAtServer()
	If ValueIsFilled(Object.Room) Then
		Object.RoomType = Object.Room.RoomType;
		If ValueIsFilled(Object.Room.Owner) Then
			Object.Hotel = Object.Room.Owner;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure DiagnoseAtServer()
	DiagnosticSteps.Clear();
	Summary = "";
	
	vObj = FormAttributeToValue("Object");
	vSteps = vObj.pmDiagnose();
	ValueToFormAttribute(vObj, "Object");
	
	vFailCount = 0;
	vWarnCount = 0;
	vFirstFail = "";
	For Each vStep In vSteps Do
		vRow = DiagnosticSteps.Add();
		FillPropertyValues(vRow, vStep);
		If vStep.Status = "FAIL" Then
			vFailCount = vFailCount + 1;
			If IsBlankString(vFirstFail) Then
				vFirstFail = vStep.Message;
			EndIf;
		ElsIf vStep.Status = "WARN" Then
			vWarnCount = vWarnCount + 1;
		EndIf;
	EndDo;
	
	If vFailCount = 0 And vWarnCount = 0 Then
		Summary = NStr("en='OK: price should be filled in the cart'; ru='OK: цена должна заполниться в корзине'; de='OK: Preis sollte im Warenkorb erscheinen'");
	ElsIf vFailCount = 0 Then
		Summary = NStr("en='Calculated with warnings. Check WARN rows.'; ru='Расчёт прошёл с предупреждениями. См. строки WARN.'; de='Berechnung mit Warnungen. WARN-Zeilen prüfen.'");
	Else
		Summary = NStr("en='Price will be 0. First problem: '; ru='Цена будет 0. Первая проблема: '; de='Preis wird 0. Erstes Problem: '") + vFirstFail;
	EndIf;
EndProcedure

#EndRegion
