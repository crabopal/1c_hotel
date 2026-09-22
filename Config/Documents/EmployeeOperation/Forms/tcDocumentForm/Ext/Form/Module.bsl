
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");      
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vMessage = "";
	vAttributeInErr = "";
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pCurrentObject.Metadata(), pCurrentObject.Ref, NStr(vMessage));
			If Not IsBlankString(vAttributeInErr) Then
				SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = vAttributeInErr;
				vUM.Text = NStr(vMessage);
				vUM.Message();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer



#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	RoomOnChangeAtServer();
EndProcedure // RoomOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	RoomTypeOnChangeAtServer();
EndProcedure // RoomTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure OperationOnChange(pItem)
	OperationOnChangeAtServer();
EndProcedure // OperationOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(pItem)
	EmployeeOnChangeAtServer();
EndProcedure // EmployeeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure OperationStartTimeOnChange(pItem)  	 
	OperationStartTimeOnChangeAtServer();	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OperationEndTimeOnChange(pItem)
	OperationEndTimeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ArticlesArticleOnChange(pItem)
	vCurRow = Items.Articles.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Article) Then
			vArticleStruct = tcOnServer.cmGetAtributeAsArray(vCurRow.Article);
			vCurRow.Unit = vArticleStruct.Unit;  
		EndIf;
	EndIf;  	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure QuantityOnChange(pItem)
	QuantityOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomSpaceOnChange(pItem)
	RoomSpaceOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NumberOfPersonsOnChange(pItem)
	NumberOfPersonsOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OperationIntentTimeOnChange(pItem)
	OperationIntentTimeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EmployeeAssignmentTimeOnChange(pItem)
	EmployeeAssignmentTimeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OperationEndConfirmedTimeOnChange(pItem)
	OperationEndConfirmedTimeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ArticlesQuantityPerUnitOnChange(pItem)
	ArticlesQuantityPerUnitOnChangeAtServer();   
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionFill(pCommand)
	ActionFillAtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Room) Then
		// Retrieve room resources
		vRoomAttrs = vObj.Room.GetObject().pmGetRoomAttributes(?(ValueIsFilled(vObj.OperationStartTime), vObj.OperationStartTime, vObj.Date));
		For Each vRoomAttrsRow In vRoomAttrs Do
			vObj.RoomType = vRoomAttrsRow.RoomType;
			Break;
		EndDo;
		// Get operation duration and room space
		If ValueIsFilled(vObj.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vObj.Operation, vObj.Hotel, vObj.RoomType, vObj.Room, vObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vObj.Duration = vObj.Quantity * vStdsRow.Duration;
				vObj.OperationEndTime = vObj.pmGetOperationEndTime();
				vObj.RoomSpace = vObj.Quantity * vStdsRow.RoomSpace;
				vObj.Price = vObj.Quantity * vStdsRow.Price;
			EndIf;
		EndIf;
		// Get number of persons in the room for the operation start date
		vObj.NumberOfPersons = vObj.pmGetNumberOfPersons();
	EndIf;
	// Recalculate durations
	vObj.pmCalculateDurations();
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RoomOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.RoomType) Then
		// Get operation duration and room space
		If ValueIsFilled(vObj.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vObj.Operation, vObj.Hotel, vObj.RoomType, vObj.Room, vObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vObj.Duration = vObj.Quantity * vStdsRow.Duration;
				vObj.OperationEndTime = vObj.pmGetOperationEndTime();
				vObj.RoomSpace = vObj.Quantity * vStdsRow.RoomSpace;
				vObj.Price = vObj.Quantity * vStdsRow.Price;
			EndIf;
		EndIf;
	EndIf;
	// Recalculate durations
	vObj.pmCalculateDurations();
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RoomTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OperationOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Operation) Then
		// Operation intent time
		If vObj.IsNew() And Not ValueIsFilled(vObj.OperationIntentTime) Then
			If ValueIsFilled(vObj.OperationStartTime) Then
				vObj.OperationIntentTime = vObj.OperationStartTime;
			Else
				vObj.OperationIntentTime = cm1SecondShift(vObj.Date);
			EndIf;
		EndIf;
		// Get operation duration and room space
		vStds = Catalogs.Operations.GetOperationStandards(vObj.Operation, vObj.Hotel, vObj.RoomType, vObj.Room, vObj.Employee);
		If vStds.Count() > 0 then
			vStdsRow = vStds.Get(0);
			vObj.Duration = vObj.Quantity * vStdsRow.Duration;
			vObj.OperationEndTime = vObj.pmGetOperationEndTime();
			vObj.RoomSpace = vObj.Quantity * vStdsRow.RoomSpace;
			vObj.Price = vObj.Quantity * vStdsRow.Price;
		EndIf;
		// Fill operation start and end PBX codes
		vObj.pmFillPBXCodes();
		// Get number of persons in the room for the operation start date
		vObj.NumberOfPersons = vObj.pmGetNumberOfPersons();
		// Fill operation articles consumption standards table
		vObj.Articles.Clear();
		vObj.pmFillArticles();
	EndIf;
	// Recalculate durations
	vObj.pmCalculateDurations();
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // OperationOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure EmployeeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Get operation duration and room space
	If ValueIsFilled(vObj.Operation) Then
		vStds = Catalogs.Operations.GetOperationStandards(vObj.Operation, vObj.Hotel, vObj.RoomType, vObj.Room, vObj.Employee);
		If vStds.Count() > 0 then
			vStdsRow = vStds.Get(0);
			vObj.Duration = vObj.Quantity * vStdsRow.Duration;
			vObj.OperationEndTime = vObj.pmGetOperationEndTime();
			vObj.RoomSpace = vObj.Quantity * vStdsRow.RoomSpace;
			vObj.Price = vObj.Quantity * vStdsRow.Price;
		EndIf;
	EndIf;
	// Fill operation start and end PBX codes
	vObj.pmFillPBXCodes();
	// Fill employee assignment time
	If ValueIsFilled(vObj.Ref) And ValueIsFilled(vObj.Employee) And Not ValueIsFilled(vObj.Ref.Employee) Then
		If Not ValueIsFilled(vObj.EmployeeAssignmentTime) Then
			vObj.EmployeeAssignmentTime = CurrentSessionDate();
		EndIf;
	ElsIf Not ValueIsFilled(vObj.Employee) And ValueIsFilled(vObj.EmployeeAssignmentTime) Then 
		vObj.EmployeeAssignmentTime = '00010101';
	EndIf;
	// Recalculate durations
	vObj.pmCalculateDurations();
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // EmployeeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OperationStartTimeOnChangeAtServer()
	vObj = FormAttributeToValue("Object"); 
	// Recalculate operation start time
	If ValueIsFilled(vObj.OperationStartTime) Then
		vObj.OperationStartTime = cm1SecondShift(vObj.OperationStartTime);
	EndIf;
	vObj.OperationEndTime = vObj.pmGetOperationEndTime();
	vObj.pmCalculateDurations();
	// Get number of persons in the room for the operation start date
	vObj.NumberOfPersons = vObj.pmGetNumberOfPersons();
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // OperationStartTimeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer()
	vObj = FormAttributeToValue("Object"); 
	vObj.OperationEndTime = vObj.pmGetOperationEndTime();
	vObj.pmCalculateDurations(); 
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure OperationEndTimeOnChangeAtServer()
	vObj = FormAttributeToValue("Object"); 
	vObj.pmCalculateDurations();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ActionFillAtServer()
	vObj = FormAttributeToValue("Object"); 
	vObj.Articles.Clear();
	vObj.pmFillArticles();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ArticlesQuantityPerUnitOnChangeAtServer()
	vCurRow = Object.Articles.FindByID(Items.Articles.CurrentRow); 
	If vCurRow <> Undefined Then
		If vCurRow.IsPerRoomSpaceUnit Then
			If vCurRow.IsPerPerson Then
				vCurRow.PlannedQuantity = Object.Quantity * vCurRow.QuantityPerUnit * Object.RoomSpace * Object.NumberOfPersons;
			Else
				vCurRow.PlannedQuantity = Object.Quantity * vCurRow.QuantityPerUnit * Object.RoomSpace;
			EndIf;
		Else
			If vCurRow.IsPerPerson Then
				vCurRow.PlannedQuantity = Object.Quantity * vCurRow.QuantityPerUnit * Object.NumberOfPersons;
			Else
				vCurRow.PlannedQuantity = Object.Quantity * vCurRow.QuantityPerUnit;
			EndIf;
		EndIf;
		vCurRow.Quantity = vCurRow.PlannedQuantity;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure QuantityOnChangeAtServer()
	vObj = FormAttributeToValue("Object"); 
	If ValueIsFilled(vObj.Operation) Then
		// Get operation duration and room space
		vStds = Catalogs.Operations.GetOperationStandards(vObj.Operation, vObj.Hotel, vObj.RoomType, vObj.Room, vObj.Employee);
		If vStds.Count() > 0 then
			vStdsRow = vStds.Get(0);
			vObj.RoomSpace = vObj.Quantity * vStdsRow.RoomSpace;
			vObj.Price = vObj.Quantity * vStdsRow.Price;
		EndIf;
		// Fill operation articles consumption standards table
		vObj.Articles.Clear();
		vObj.pmFillArticles();
	EndIf;  
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure RoomSpaceOnChangeAtServer()
	vObj = FormAttributeToValue("Object"); 
	If ValueIsFilled(vObj.Operation) Then
		// Fill operation articles consumption standards table
		vObj.Articles.Clear();
		vObj.pmFillArticles();
	EndIf;
	ValueToFormAttribute(vObj, "Object");       
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure NumberOfPersonsOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Operation) Then
		// Fill operation articles consumption standards table
		vObj.Articles.Clear();
		vObj.pmFillArticles();
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(vObj.OldDate) Then
		If Year(vObj.OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		vObj.OldDate = vObj.Date;
	EndIf;
	ValueToFormAttribute(vObj, "Object");  
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure OperationIntentTimeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateDurations();  
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure EmployeeAssignmentTimeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateDurations();  
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure OperationEndConfirmedTimeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateDurations();  
	ValueToFormAttribute(vObj, "Object");
EndProcedure

#EndRegion


