
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	// Fill employee that closed message and date and time when it was closed
	If IsClosed And Not ValueIsFilled(DateWhenClosed) Then
		DateWhenClosed = CurrentSessionDate();
		ClosedBy = SessionParameters.CurrentUser;
		Write(DocumentWriteMode.Write);
	ElsIf Not IsClosed And ValueIsFilled(DateWhenClosed) Then
		DateWhenClosed = Undefined;
		ClosedBy = Catalogs.Employees.EmptyRef();
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// Clear register records
	RegisterRecords.Messages.Clear();
	
	// Build list of accounting dates
	vDates = New ValueList();
	If Type = Enums.MessageTypes.Activity And ValueIsFilled(ActivityStartTime) Then
		vDates.Add(BegOfDay(ActivityStartTime));
	ElsIf ValueIsFilled(CloseToDate) Then
		vDates.Add(BegOfDay(CloseToDate));
	ElsIf ValueIsFilled(ValidToDate) Then
		vDates.Add(BegOfDay(ValidToDate));
	ElsIf ValueIsFilled(ValidFromDate) Then
		vDates.Add(BegOfDay(ValidFromDate));
	Else
		vDates.Add(BegOfDay(Date));
	EndIf;
	
	// Do for each day in message period
	For Each vDatesItem In vDates Do
		vAccountingDate = vDatesItem.Value;
		
		// Post to messages register
		Record = RegisterRecords.Messages.Add();
		
		FillPropertyValues(Record, ThisObject);
		Record.AccountingDate = vAccountingDate;
		Record.Period = Date;
		Record.Object = ByObject;
		
		For Each vEmployeeRow In ForEmployees Do
			If ValueIsFilled(vEmployeeRow.Employee) Then
				Record = RegisterRecords.Messages.Add();
				
				FillPropertyValues(Record, ThisObject);
				Record.AccountingDate = vAccountingDate; 
				Record.Period = Date;
				Record.Object = ByObject;
						
				Record.ForEmployee = vEmployeeRow.Employee;
				Record.ForDepartment = Undefined;
			EndIf;
		EndDo;
		
		For Each vDepartmentRow In ForDepartments Do
			If ValueIsFilled(vDepartmentRow.Department) Then
				Record = RegisterRecords.Messages.Add();
				
				FillPropertyValues(Record, ThisObject);
				Record.AccountingDate = vAccountingDate;
				Record.Period = Date;
				Record.Object = ByObject;
						
				Record.ForEmployee = Undefined;
				Record.ForDepartment = vDepartmentRow.Department;
			EndIf;
		EndDo;
	EndDo;

	// Write register records
	RegisterRecords.Messages.Write();
	
	// Post message operations
	PostOperations();
	
	// Process actions after message is closed
	If IsClosed And AdditionalProperties.Property("MessageToBeClosed") And AdditionalProperties.MessageToBeClosed And ValueIsFilled(Hotel) Then
		If Type = Enums.MessageTypes.Task And ValueIsFilled(MessageType) Then
			If MessageType.SetRoomStatusAtTaskEnd And ValueIsFilled(ByObject) And TypeOf(ByObject) = Type("CatalogRef.Rooms") And Not ByObject.IsFolder Then
				If ValueIsFilled(RoomStatus) And RoomStatus <> ByObject.RoomStatus Then
					vRoomObj = ByObject.GetObject();
					vRoomObj.RoomStatus = RoomStatus;
					vRoomObj.Write();
		
					// This is room change operation
					vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, TrimAll(MessageType) + " - " + String(Ref));
				EndIf;
			EndIf;
			If MessageType.SetBedsSetupAtTaskEnd And ValueIsFilled(ByObject) And TypeOf(ByObject) = Type("CatalogRef.Rooms") And Not ByObject.IsFolder Then
				If BedsSetup <> ByObject.BedsSetup Then
					vRoomObj = ByObject.GetObject();
					vRoomObj.BedsSetup = BedsSetup;
					vRoomObj.Write();
		
					// This is room change operation
					vRoomObj.pmWriteToRoomChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Function CheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Type) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Typ> Attribut sollte gefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Type", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Remarks) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Текст сообщения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Remarks> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Remarks> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Remarks", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Ref) And IsClosed Or ValueIsFilled(Ref) And Not Ref.IsClosed And IsClosed Then
		If Not cmCheckUserPermissions("HavePermissionToCloseOpenTasks") Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Нет прав на закрытие открытых задач!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "You do not have permissions to close open tasks!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte, offene Aufgaben zu schließen!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", ?(ValueIsFilled(MessageStatus), "MessageStatus", "IsClosed"), pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If ValueIsFilled(SessionParameters.CurrentHotel) And ValueIsFilled(SessionParameters.CurrentHotel.MessageStatus) Then
		MessageStatus = SessionParameters.CurrentHotel.MessageStatus;
	EndIf;
	IsClosed = False;
	ClosedBy = Undefined;
	DateWhenClosed = Undefined;
	SMSIsSent = False;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)  
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If pWriteMode = DocumentWriteMode.Posting Then    
		vFuncLogName = NStr("en='SMS.SendMessage'; ru='SMS.SendMessage'; de='SMS.SendMessage'");
		If TypeOf(ByObject) = Type("CatalogRef.Rooms") And Not ValueIsFilled(Ref) Then			
			vRef = Documents.Message.GetRef();
			SetNewObjectRef(vRef);
			Catalogs.ChatBots.AddNotification(vRef, ByObject.Owner, ForDepartment, "Появилась новая задача!","");
		EndIf;
		If Not ValueIsFilled(Hotel) And ValueIsFilled(ByObject) Then  
			If Not ByObject.Metadata().Attributes.Find("Hotel") = Undefined Then
				Hotel = ByObject.Hotel;
			ElsIf TypeOf(ByObject) = Type("CatalogRef.Rooms") Or TypeOf(ByObject) = Type("CatalogRef.GuestGroups") Then
				Hotel = ByObject.Owner;
			EndIf;	
		EndIf;

		If Type <> Enums.MessageTypes.Activity Then
			ActivityStartTime = '00010101';
			ActivityEndTime = '00010101';
		EndIf;
		If ValueIsFilled(Ref) Then
			For Each vOprRow In Ref.Operations Do
				If ValueIsFilled(vOprRow.EmployeeOperation) And Not vOprRow.EmployeeOperation.DeletionMark Then
					vDocObj = vOprRow.EmployeeOperation.GetObject();
					vDocObj.SetDeletionMark(True);
				EndIf;
			EndDo;
			If Not Ref.IsClosed And IsClosed Then
				AdditionalProperties.Insert("MessageToBeClosed", True);
			EndIf;
		EndIf;
		
		If SendBySMS And SMSIsSent = False Then
			If ValidFromDate <= CurrentSessionDate() Then
				vError = "";

				If ValueIsFilled(ForEmployee) Then  
					If Not ValueIsFilled(Hotel) Then
						Hotel = ForEmployee.Hotel;	
					EndIf;
				EndIf;

				vEmployeesList = New ValueList();
				If ValueIsFilled(ForEmployee) Then
					vEmployeesList.Add(ForEmployee);
				EndIf;
				If ForEmployees.Count() > 0 Then
					For Each vForEmployeesRow In ForEmployees Do
						If ValueIsFilled(vForEmployeesRow.Employee) Then
							If vEmployeesList.FindByValue(vForEmployeesRow.Employee) = Undefined Then
								vEmployeesList.Add(vForEmployeesRow.Employee);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
 
				vDepartmentsList = New ValueList();
				If ValueIsFilled(ForDepartment) Then
					vDepartmentsList.Add(ForDepartment);
				EndIf;
				If ForDepartments.Count() > 0 Then
					For Each vForDepartmentsRow In ForDepartments Do
						If ValueIsFilled(vForDepartmentsRow.Department) Then
							If vDepartmentsList.FindByValue(vForDepartmentsRow.Department) = Undefined Then
								vDepartmentsList.Add(vForDepartmentsRow.Department);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				
				vPhonesList = New ValueList();
				
				For Each vEmployeesListItem In vEmployeesList Do
					vForEmployee = vEmployeesListItem.Value;

					// Try sent in telegram
					If ValueIsFilled(Hotel) Then 
						SMSIsSent = Catalogs.ChatBots.SendEmployeeMessage(Hotel, vForEmployee, Remarks);
					EndIf;
					
					// Try send sms     
					If Not SMSIsSent Then
						If ValueIsFilled(vForEmployee.Phones) Then
							vCommaPosition = Find(vForEmployee.Phones, ",");
							vPhoneNumber = ?(vCommaPosition = 0, SMS.GetValidPhoneNumber(vForEmployee.Phones), SMS.GetValidPhoneNumber(Left(vForEmployee.Phones, vCommaPosition - 1)));
							If vPhonesList.FindByValue(vPhoneNumber) = Undefined Then
								vPhonesList.Add(vPhoneNumber);
								
								If SMS.SendMessage(Remarks, vPhoneNumber, , , , , vForEmployee, , vError) Then
									SMSIsSent = True;
								Else
									SMSIsSent = False;
									tcCommonFunctionOnClientServer.TextMessage(vError);
									WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Ref, vError, EventLogEntryTransactionMode.Independent);
								EndIf;
							EndIf;
						Else
							vError = NStr("en = 'The employee do not have a phone number!'; de = 'Bei dem Mitarbeiter ist keine Telefonnummer angegeben!'; ru = 'У сотрудника не указан номер телефона!'");
							SMSIsSent = False;
							tcCommonFunctionOnClientServer.TextMessage(vError);
							WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Ref, vError, EventLogEntryTransactionMode.Independent);
						EndIf;  
					EndIf;
				EndDo;
				
				For Each vDepartmentsListItem In vDepartmentsList Do
					vForDepartment = vDepartmentsListItem.Value;

					vQuery = New Query;
					vQuery.Text = "SELECT
					|	Employees.Ref AS Employee,
					|	Employees.Phones AS Phones
					|FROM
					|	Catalog.Employees AS Employees
					|WHERE
					|	Employees.Department = &qDepartment
					|	AND NOT Employees.IsFolder
					|	AND NOT Employees.DeletionMark";
					vQuery.SetParameter("qDepartment", vForDepartment);
					vPhoneNumbers = vQuery.Execute().Unload();
					For Each vPhoneNumberChoice In vPhoneNumbers Do   
						If Not ValueIsFilled(Hotel) Then
							Hotel = vPhoneNumberChoice.Employee.Hotel;	
						EndIf;	                       

						// Try sent in telegram
						If ValueIsFilled(Hotel) Then 
							SMSIsSent = Catalogs.ChatBots.SendEmployeeMessage(Hotel, vPhoneNumberChoice.Employee, Remarks);
						EndIf;  

						// Try send sms     
						If Not SMSIsSent And Not IsBlankString(vPhoneNumberChoice.Phones) Then
							vCommaPosition = Find(vPhoneNumberChoice.Phones, ",");
							vPhoneNumber = ?(vCommaPosition = 0, SMS.GetValidPhoneNumber(vPhoneNumberChoice.Phones), SMS.GetValidPhoneNumber(Left(vPhoneNumberChoice.Phones, vCommaPosition-1)));
							If vPhonesList.FindByValue(vPhoneNumber) = Undefined Then
								vPhonesList.Add(vPhoneNumber);
								
								If SMS.SendMessage(Remarks, vPhoneNumber, , , , , vPhoneNumberChoice.Employee,, vError) Then
									SMSIsSent = True;
								Else
									SMSIsSent = False;
									tcCommonFunctionOnClientServer.TextMessage(vError);
									WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Ref, vError, EventLogEntryTransactionMode.Independent);
								EndIf;  
							EndIf;  
						EndIf;
					EndDo;
					If ValueIsFilled(vForDepartment.HeadOfDepartment) Then
						vHeadOfDepartment = vForDepartment.HeadOfDepartment;
						If Not IsBlankString(vHeadOfDepartment.Phones) Then
							If vPhoneNumbers.Find(vHeadOfDepartment, "Employee") = Undefined Then
								vCommaPosition = Find(vHeadOfDepartment.Phones, ",");
								vPhoneNumber = ?(vCommaPosition = 0, SMS.GetValidPhoneNumber(vHeadOfDepartment.Phones), SMS.GetValidPhoneNumber(Left(vHeadOfDepartment.Phones, vCommaPosition-1)));
								If vPhonesList.FindByValue(vPhoneNumber) = Undefined Then
									vPhonesList.Add(vPhoneNumber);
									
									If SMS.SendMessage(Remarks, vPhoneNumber, , , , , vHeadOfDepartment,, vError) Then
										SMSIsSent = True;
									Else
										SMSIsSent = False;
										tcCommonFunctionOnClientServer.TextMessage(vError);
										WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Ref, vError, EventLogEntryTransactionMode.Independent);
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	ElsIf DeletionMark Then
		If Posted And IsClosed Then
			If Not IsInRole("Administrator") Then
				Raise NStr("en='Document is closed! Could not be deleted'; ru='Документ закрыт! Помечать на удаление запрещено'; de='Das Dokument ist geschlossen! Das Markieren zum Löschen ist verboten'") + " - " + TrimAll(Ref);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure PostOperations()
	If ValueIsFilled(ByObject) And TypeOf(ByObject) = Type("CatalogRef.Rooms") Then
		vRoom = ByObject;
		For Each vOprRow In Operations Do
			If Not ValueIsFilled(vOprRow.Operation) Then
				Continue;
			EndIf;
			
			// Build operation document
			If ValueIsFilled(vOprRow.EmployeeOperation) Then
				vDocObj = vOprRow.EmployeeOperation.GetObject();
				vDocObj.DeletionMark = False;
			Else
				vDocObj = Documents.EmployeeOperation.CreateDocument();
				vDocObj.Hotel = vRoom.Owner;
				vDocObj.pmFillAttributesWithDefaultValues();
			EndIf;
			vDocObj.Date = Date;
			vDocObj.SetTime(AutoTimeMode.DontUse);
			vDocObj.Employee = vOprRow.Employee;
			vDocObj.RoomType = vRoom.RoomType;
			vDocObj.Room = vRoom;
			vDocObj.Operation = vOprRow.Operation;
			// Operation start time
			If ValueIsFilled(vOprRow.OperationStartTime) Then
				vDocObj.OperationStartTime = vOprRow.OperationStartTime;
			Else
				vDocObj.OperationStartTime = cm1SecondShift(Date);
			EndIf;
			vDocObj.OperationIntentTime = vDocObj.OperationStartTime;
			// Operation duration
			If ValueIsFilled(vOprRow.OperationEndTime) Then
				vDocObj.Duration = vOprRow.Duration;
				vDocObj.OperationEndTime = vOprRow.OperationEndTime;
			EndIf;
			// Get operation standards
			vStds = Catalogs.Operations.GetOperationStandards(vDocObj.Operation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
			If vStds.Count() > 0 Then
				vStdsRow = vStds.Get(0);
				If Not ValueIsFilled(vDocObj.OperationEndTime) Then
					vDocObj.Duration = vStdsRow.Duration;
					vDocObj.OperationEndTime = vDocObj.pmGetOperationEndTime();
				EndIf;
				vDocObj.RoomSpace = vStdsRow.RoomSpace;
				vDocObj.Price = vStdsRow.Price;
			EndIf;
			// Quantity
			If vOprRow.Quantity <> 0 Then
				vDocObj.Quantity = vOprRow.Quantity;
			Else
				vDocObj.Quantity = 1;
			EndIf;
			vDocObj.NumberOfPersons = 1;
			If vOprRow.Price <> 0 Then
				vDocObj.Price = vOprRow.Price;
			EndIf;
			// Fill operation articles consumption standards table
			vDocObj.Articles.Clear();
			vDocObj.pmFillArticles();
			// Post document
			vDocObj.Write(DocumentWriteMode.Posting);
			// Save link to the posted operation
			vOprRow.EmployeeOperation = vDocObj.Ref;
		EndDo;
		If Modified() Then
			Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;
EndProcedure // PostOperations

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	For Each vOprRow In Operations Do
		If ValueIsFilled(vOprRow.EmployeeOperation) And Not vOprRow.EmployeeOperation.DeletionMark Then
			vDocObj = vOprRow.EmployeeOperation.GetObject();
			vDocObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // UndoPosting

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill hotel
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Fill message status
	If Not ValueIsFilled(MessageStatus) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.MessageStatus) Then
			Type = Enums.MessageTypes.Task;
			MessageStatus = Hotel.MessageStatus;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCommentText - String - Comment text
//
Procedure pmAddComment(pCommentText = "") Export
	vCommentRow = Comments.Add();
	vCommentRow.Period = CurrentSessionDate();
	vCommentRow.Employee = SessionParameters.CurrentUser;
	vCommentRow.Comments = TrimR(pCommentText);
EndProcedure // pmAddComment

#EndRegion
