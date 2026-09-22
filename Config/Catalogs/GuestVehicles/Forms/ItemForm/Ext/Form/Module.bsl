
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	AppearanceCarNumber(True);
	vCarNum = TrimAll(Object.CarNumber);
	If Object.FreeFormInput = False And Not IsBlankString(vCarNum) Then
		A1 = Left(vCarNum, 1);
		A2 = Mid(vCarNum,2,3);
		A3 = Mid(vCarNum,5,2);
		A4 = Mid(vCarNum,7,3);
	EndIf;	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Object.Description = Object.CarNumber + " " + Object.Brand + " " + Object.Model;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FreeFormInputOnChange(Item)
	AppearanceCarNumber();
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CarNumberAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pText = TrimAll(pText);
	If IsBlankString(pText) Then
		Return;
	EndIf;	
	vAllowedLletters = New Array;
	vAllowedLletters.Add("A");
	vAllowedLletters.Add("B");
	vAllowedLletters.Add("C");
	vAllowedLletters.Add("E");
	vAllowedLletters.Add("K");
	vAllowedLletters.Add("M");
	vAllowedLletters.Add("H");
	vAllowedLletters.Add("O");
	vAllowedLletters.Add("P");
	vAllowedLletters.Add("T");
	vAllowedLletters.Add("X");
	vAllowedLletters.Add("Y");
	
	//A, B, E, K, M, H, O, P, C, T, Y, X
	pText = StrReplace(pText, "А", "A");
	pText = StrReplace(pText, "В", "B");
	pText = StrReplace(pText, "Е", "E");
	pText = StrReplace(pText, "С", "C");
	pText = StrReplace(pText, "К", "K");
	pText = StrReplace(pText, "М", "M");
	pText = StrReplace(pText, "Н", "H");
	pText = StrReplace(pText, "О", "O");
	pText = StrReplace(pText, "Р", "P");
	pText = StrReplace(pText, "Т", "T");
	pText = StrReplace(pText, "Х", "X");
	pText = StrReplace(pText, "У", "Y");

	If pItem.Name = "A1" Then
		If vAllowedLletters.Find(pText) = Undefined Then
			A1 = "";
		Else
			CurrentItem = Items.A2;
			A1 = pText;
		EndIf;	
	ElsIf pItem.Name = "A2" Then
			Try
				vIsNumber = Number(pText);
				If StrLen(pText) = 3 Then
					CurrentItem = Items.A3;
				EndIf;
			Except
				A2 = "";
			EndTry;	
	ElsIf pItem.Name = "A3" Then
		vChecked = False;
		For i =1 To StrLen(pText) Do
			vChar = Mid(pText, i, 1);
			If vAllowedLletters.Find(vChar) = Undefined Then
				A3 = "";
				vChecked = False;
				Break;
			Else	
				vChecked = True;
			EndIf;
		EndDo;
		If vChecked  And StrLen(pText) = 2 Then 	
			CurrentItem = Items.A4;
			A3 = pText;
		EndIf;
	ElsIf pItem.Name = "A4" Then
		Try
			vIsNumber = Number(pText);
			If StrLen(pText) = 3 Then
				CurrentItem = Items.Brand;
			EndIf;
		Except
			A4 = "";
		EndTry;	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure WriteAndClose(Command)
	If Object.FreeFormInput = False Then
		Object.CarNumber = A1 + A2 + A3 + A4;
		If StrLen(Object.CarNumber) < 8 Then
			Message = New UserMessage;
			Message.Text = Nstr("en = 'Check the correctness of entering the car number'; de = 'Überprüfen Sie die Richtigkeit der Eingabe der Autonummer'; ru = 'Проверьте корректность ввода номера авто'");
			Message.Message();
			Return;
		EndIf;
	EndIf;	
	If ThisObject.Write() Then
		Close(Object.Ref);
	EndIf;	
EndProcedure

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure AppearanceCarNumber(pOnOpen = False)
	If Object.FreeFormInput Then
		If pOnOpen = False Then
			Object.CarNumber = A1 + A2 + A3 + A4;
		EndIf;	
		Items.GroupPlate.Visible = False;
		Items.CarNumber.Visible = True;
	Else
		vCarNum = TrimAll(Object.CarNumber);
		If Not IsBlankString(vCarNum)  Then
			A1 = Left(vCarNum, 1);
			A2 = Mid(vCarNum, 2, 3);
			A3 = Mid(vCarNum, 5, 2);
			A4 = Mid(vCarNum, 7, 3);
		EndIf;
		Items.GroupPlate.Visible = True;
		Items.CarNumber.Visible = False;
	EndIf;	
EndProcedure

#EndRegion  
