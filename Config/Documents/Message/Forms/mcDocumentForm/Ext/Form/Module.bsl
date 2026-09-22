
#Region Variables

&AtServer
var vTempArray;

#EndRegion   

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	vObject = FormAttributeToValue("Object");
	vTempArray = New Array();
	
    pNewForm = Parameters.Key.IsEmpty();
	If pNewForm Then
		vObject.pmFillAttributesWithDefaultValues();
		Items.GroupMessage.Title = "" + vObject.Author;
	Else
		Items.GroupMessage.Title = Format(vObject.Date, "DF='dd.MM.yyyy HH:mm'") + " - " + vObject.Author + " - " + TrimAll(vObject.Number);
	EndIf;
	
	If Parameters.Property("Type") Then
		If TypeOf(Parameters.Type) = Type("EnumRef.MessageTypes") Then
			vObject.Type = Parameters.Type;
		EndIf;
	EndIf;
	If Parameters.Property("SetParamObject") Then
		If Not ValueIsFilled(vObject.ByObject) Then
			vObject.ByObject = Parameters.SetParamObject;
		EndIf;		
		If TypeOf(vObject.ByObject) = Type("CatalogRef.Rooms") Then
			SelRoom = vObject.ByObject;
		EndIf;
	EndIf;
	If Parameters.Property("SetEmployee") Then
		vObject.ForEmployee = Parameters.SetEmployee;
	EndIf;
	If Parameters.Property("SetOrder") Then
		vObject.ByOrder = Parameters.SetOrder;
	EndIf;
	If Parameters.Property("SetDepartment") Then
		vObject.ForDepartment = Parameters.SetDepartment;
	EndIf;
	If Parameters.Property("SetRemarks") Then
		vObject.Remarks = Parameters.SetRemarks;
	EndIf;
	If Parameters.Property("SetType") Then
		vObject.MessageType = Parameters.SetType;
	EndIf;
		
	// Check if there are any message types defined
	vMessageTypes = cmGetAllMessageTypes();
	If vMessageTypes.Count() = 0 Then
		Items.MessageType.Visible = False;
	Else
		Items.MessageType.Visible = True;
	EndIf;

	// Check if there are any message statuses defined
	vMessageStatuses = cmGetAllMessageStatuses();
	If vMessageStatuses.Count() = 0 Then
		Items.MessageStatus.Visible = False;
		Items.IsClosed.Visible = True;
	Else
		Items.IsClosed.Visible = False;
		Items.MessageStatus.Visible = True;
	EndIf;
	
	// Comments
	cNewPolAtServer();
	
	If vObject.IsClosed And Not(pNewForm) Then
		pEnabled = False;
		EnableAllItems(pEnabled, pNewForm);
	Else
		pEnabled = True;
		EnableAllItems(pEnabled, pNewForm);
	EndIf;
	
	If ValueIsFilled(SelRoom) And SelRoom = vObject.ByObject Then
		Items.ByObject.Visible = False;
	ElsIf ValueIsFilled(vObject.ByObject) And TypeOf(vObject.ByObject) <> Type("CatalogRef.Rooms") Then
		Items.SelRoom.Visible = False;
	EndIf;
	
	Items.GroupWhenClosed.Visible = vObject.IsClosed;
		
	ValueToFormAttribute(vObject, "Object");
	
	SetFormAppearanceAtServer();
EndProcedure //  OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	FillEmployeesPresentation();
	FillDepartmentsPresentation();
EndProcedure //  OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not IsBlankString(ThisObject["CommentFinish"]) Then
		CommandAddComment(Commands["CommandAddComment"]);
	EndIf;
EndProcedure //  BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("MessageWrite", , ThisObject);
EndProcedure //  AfterWrite 

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IsClosedOnChange(Item)
	If Object.IsClosed Then
		EnableAllItems(False);
	Else
		EnableAllItems(True);
	EndIf;
EndProcedure //  IsClosedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	Object.ByObject = SelRoom;
	If ValueIsFilled(SelRoom) Then
		Items.ByObject.Visible = False;
	Else
		Items.ByObject.Visible = True;
	EndIf;
	SetReservationTaskAreaAppearanceAtServer();
EndProcedure //  SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ByObjectOnChange(Item)
	If Not ValueIsFilled(Object.ByObject) Then
		SelRoom = PredefinedValue("Catalog.Rooms.EmptyRef");
		Items.SelRoom.Visible = True;
	ElsIf TypeOf(Object.ByObject) <> Type("CatalogRef.Rooms") Then
		SelRoom = PredefinedValue("Catalog.Rooms.EmptyRef");
		Items.SelRoom.Visible = False;
	Else
		SelRoom = Object.ByObject;
		Items.SelRoom.Visible = True;
	EndIf;
	SetReservationTaskAreaAppearanceAtServer();
EndProcedure //  ByObjectOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MessageStatusOnChange(pItem)
	If ValueIsFilled(Object.MessageStatus) Then
		Object.IsClosed = tcOnServer.cmGetAttributeByRef(Object.MessageStatus, "IsClosed");
	EndIf;
	Modified = True;
EndProcedure //  MessageStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(pItem)
	SetFormAppearanceAtServer();
	FillEmployeesPresentation();
EndProcedure //  TypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ActivityStartTimeOnChange(Item)
	If ValueIsFilled(Object.ActivityStartTime) Then
		Object.ActivityEndTime = Object.ActivityStartTime + 15*60;
	Else
		Object.ActivityEndTime = '00010101';
	EndIf;
EndProcedure //  ActivityStartTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ActivityEndTimeOnChange(Item)
	If ValueIsFilled(Object.ActivityEndTime) Then
		If Not ValueIsFilled(Object.ActivityStartTime) Then
			Object.ActivityStartTime = Object.ActivityEndTime - 15*60;
		ElsIf Object.ActivityEndTime <= Object.ActivityStartTime Then
			Object.ActivityStartTime = Object.ActivityEndTime - 15*60;
		EndIf;
	Else
		Object.ActivityStartTime = '00010101';
	EndIf;
EndProcedure //  ActivityEndTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ForDepartmentClearing(pItem, pStandardProcessing)
	ForDepartmentClearingAtServer();
	RefreshDataRepresentation();
	Modified = True;
EndProcedure //  ForDepartmentClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationsOperationStartTimeOnChange(pItem)
	vOprRow = Items.Operations.CurrentData;
	If vOprRow <> Undefined Then
		If ValueIsFilled(vOprRow.OperationStartTime) Then
			If vOprRow.Duration <> 0 Then
				vOprRow.OperationEndTime = vOprRow.OperationStartTime + vOprRow.Duration*60;
			EndIf;
		Else
			vOprRow.Duration = 0;
			vOprRow.OperationEndTime = '00010101';
		EndIf;
	EndIf;
EndProcedure //  OperationsOperationStartTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationsOperationEndTimeOnChange(pItem)
	vOprRow = Items.Operations.CurrentData;
	If vOprRow <> Undefined Then
		If ValueIsFilled(vOprRow.OperationEndTime) Then
			If vOprRow.Duration <> 0 Then
				vDuration = Int((vOprRow.OperationEndTime - vOprRow.OperationStartTime)/60);
				If vDuration > 0 Then
					vOprRow.Duration = vDuration;
				Else
					vOprRow.OperationStartTime = vOprRow.OperationEndTime - vOprRow.Duration*60;
				EndIf;
			EndIf;
		Else
			vOprRow.Duration = 0;
			vOprRow.OperationStartTime = '00010101';
		EndIf;
	EndIf;
EndProcedure //  OperationsOperationEndTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationsDurationOnChange(pItem)
	vOprRow = Items.Operations.CurrentData;
	If vOprRow <> Undefined Then
		If vOprRow.Duration <> 0 Then
			If ValueIsFilled(vOprRow.OperationStartTime) Then
				vOprRow.OperationEndTime = vOprRow.OperationStartTime + vOprRow.Duration*60;
			Else
				vOprRow.OperationEndTime = '00010101';
			EndIf;
		Else
			vOprRow.OperationEndTime = '00010101';
		EndIf;
	EndIf;
EndProcedure //  OperationsDurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vOprRow = Items.Operations.CurrentData;
	If vOprRow <> Undefined And Items.Operations.CurrentItem <> Undefined And Items.Operations.CurrentItem.Name = "OperationsEmployeeOperation" Then
		If ValueIsFilled(vOprRow.EmployeeOperation) Then
			ShowValue(,vOprRow.EmployeeOperation);
		EndIf;
	EndIf;
EndProcedure //  OperationsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationTaskAreaOnChange(pItem)
	If ValueIsFilled(Object.ReservationTaskArea) Then
		If Not Object.PopUp Then
			Object.PopUp = True;
		EndIf;
	EndIf;
EndProcedure //  ReservationTaskAreaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonOnChange(pItem)
	ContactPersonOnChangeAtServer();
EndProcedure //  ContactPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonStartChoice(pItem, pChoiceData, pStandardProcessing)
	vCPList = ContactPersonStartChoiceAtServer(Object.ByObject);
	If vCPList.Count() > 0 Then
		pStandardProcessing = False;
		ShowChooseFromList(New NotifyDescription("ContactPersonAfterChoice", ThisObject), vCPList, Items.ContactPerson, vCPList.FindByValue(Object.ContactPerson));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MessageTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vMessageTypeList = GetMessageTypeListAtServer();
	If vMessageTypeList.Count() > 0 Then
		vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en = 'Select message type'; de = 'Wählen Sie den Nachrichtentyp'; ru = 'Выберите тип сообщения'"), vMessageTypeList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("MessageTypeStartChoice_AfterInput", ThisObject));
	EndIf;
EndProcedure //  MessageTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure MessageTypeStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	Object.MessageType = pValue.Value; 
	MessageTypeOnChangeAtServer();
	FillDepartmentsPresentation();
	Modified = True;
EndProcedure //  EmployeesStartChoice_AfterInput

// -----------------------------------------------------------------------------
&AtClient
Procedure ForEmployeeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vEmployeesList = GetEmployeesListAtServer();
	vParams = New Structure("MultipleChoice, Title, ValueList", True, NStr("en='Check employees...'; ru='Отметьте сотрудников...'; de='Markieren Mitarbeiter...'"), vEmployeesList);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("EmployeesStartChoice_AfterInput", ThisObject));
EndProcedure //  ForEmployeeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ForEmployeeClearing(pItem, pStandardProcessing)
	ForEmployeeClearingAtServer();
	RefreshDataRepresentation();
	Modified = True;
EndProcedure //  ForEmployeeClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure ForDepartmentStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vDepartmentsList = GetDepartmentsListAtServer();
	vParams = New Structure("MultipleChoice, Title, ValueList", True, NStr("en='Check departments...'; ru='Отметьте отделы...'; de='Markieren Abteilungen...'"), vDepartmentsList);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("DepartmentsStartChoice_AfterInput", ThisObject));
EndProcedure //  ForDepartmentStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DepartmentsStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	SaveDepartmentsAtServer(pValue);
	RefreshDataRepresentation();
	Modified = True;
EndProcedure //  DepartmentsStartChoice_AfterInput

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandAddComment(Command)
	addNewCommentsServer();
EndProcedure //  CommandAddComment

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandDeletComment(Command)
	DeleteServer();
EndProcedure //  CommandDeletComment

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure cNewPolAtServer()
	vEnabled = False;
	
	vCount = Object.Comments.Count();
	For Each vCommentRow In Object.Comments Do
		vNameIndex = Format(vCommentRow.LineNumber, "NFD=; NG=");
		
		vTempArray.Clear();
		
		If vCount = vCommentRow.LineNumber Then
			If vCommentRow.Employee = SessionParameters.CurrentUser Then
				vEnabled = True;
			EndIf;
		EndIf;
		
	    addNewItemsForms(vNameIndex,vCommentRow,vEnabled);
	EndDo;
	
	vTempArray.Clear();			
	vTempArray.Add(New FormAttribute("CommentFinish", New TypeDescription("String"), , "Comment finish"));
	ChangeAttributes(vTempArray);
    addCommandcommentFinish();
EndProcedure //  cNewPolAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure addCommandcommentFinish()
	// Delete Items
	If Not(Items.Find("CommentFieldFinish")=Undefined) Then
		Items.Delete(Items.CommentGroupFinish);
	EndIf;
		
	// Create new group (BlockGroup) 
	vCommentGroup = Items.Add("CommentGroupFinish", Type("FormGroup"), Items.GroupMessage);
	vCommentGroup.Type = FormGroupType.UsualGroup;
	vCommentGroup.Representation = UsualGroupRepresentation.None;
	vCommentGroup.Group = ChildFormItemsGroup.Vertical;
	vCommentGroup.Title = NStr("ru = 'Новый комментарий!'; en = 'New Comment!'; de = 'Neuer Kommentar!'");
	vCommentGroup.ToolTip = vCommentGroup.Title;
	vCommentGroup.ShowTitle = True;
	vCommentGroup.HorizontalStretch = True;
	
	vCommentField = Items.Add("CommentFieldFinish", Type("FormField"), vCommentGroup);
	vCommentField.Type = FormFieldType.InputField;
	vCommentField.DataPath = "CommentFinish";
	vCommentField.TitleLocation = FormItemTitleLocation.None;
	vCommentField.ToolTip = "";
	vCommentField.AutoMaxWidth = False;
	vcommentField.Enabled=True;
	
	// Create new Button (AddComment) >
	vPrintButton = Items.Add("AddComment", Type("FormButton"), vCommentGroup);
	vPrintButton.Title = NStr("ru = 'Добавить комментарий'; en = 'Add Comment'; de = 'Kommentar hinzufügen'");
	vPrintButton.Type = FormButtonType.UsualButton;
	vPrintButton.Enabled = True;
	vPrintButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	vPrintButton.CommandName = "CommandAddComment";
	vPrintButton.SkipOnInput = True;

	ThisObject["CommentFinish"] =  "";
EndProcedure //  AddCommandcommentFinish	

// -----------------------------------------------------------------------------
&AtServer
Procedure EnableAllItems(pEnabled, pNewForm=False)
	Items.Type.Enabled = pEnabled;
	Items.MessageType.Enabled = pEnabled;
	Items.ForEmployee.Enabled = pEnabled;
	Items.ForDepartment.Enabled = pEnabled;
	Items.CloseToDate.Enabled = pEnabled;
	Items.ValidFromDate.Enabled = pEnabled;
	Items.ValidToDate.Enabled = pEnabled;
	Items.ActivityStartTime.Enabled = pEnabled;
	Items.ActivityEndTime.Enabled = pEnabled;
	Items.ContactPerson.Enabled = pEnabled;
	Items.GroupMessageHeaderRow.Enabled = pEnabled;
	If Not (Object.Author = SessionParameters.CurrentUser) And 
		Not cmCheckUserPermissions("HavePermissionToEditAllMessages") And Not(pNewForm) Then
		Items.GroupRemarks.Enabled = False;
	Else
		Items.GroupRemarks.Enabled = pEnabled;
	EndIf;
	Items.SendBySMS.Enabled = pEnabled;
	Items.PopUp.Enabled = pEnabled;
	
	If vNumberDelete > 0 Then
		vCommentGroup = Items.Find("CommentGroup"+String(vNumberDelete));
		vCommentGroup.Enabled = pEnabled;
		
		vCommentGroup = Items.Find("CommentGroupFinish");
		vCommentGroup.Enabled = pEnabled;
	EndIf;
EndProcedure //  EnableAllItems

// -----------------------------------------------------------------------------
&AtServer
Procedure addNewCommentsServer()
	vTempArray = New Array();
	
	Obj = FormAttributeToValue("Object");
	newComments = Obj.Comments.Add();
	newComments.Period = CurrentSessionDate();
	newComments.Employee = SessionParameters.CurrentUser;
	newComments.MessageStatus = Obj.MessageStatus;
	newComments.Comments = ThisObject["CommentFinish"];
	ValueToFormAttribute(Obj, "Object");
	
	vNameIndex = Format(newComments.LineNumber, "NFD=; NG=");
	vEnabled = True;
	addNewItemsForms(vNameIndex,newComments,vEnabled);
	
	addCommandcommentFinish();
EndProcedure //  AddNewCommentsServer

// -----------------------------------------------------------------------------
&AtServer
Procedure addNewItemsForms(vNameIndex,vCommentRow,vEnabled)	
	vTempArray.Add(New FormAttribute("Comment" + vNameIndex, New TypeDescription("String"), , "Comment"));
	
	ChangeAttributes(vTempArray);
	
	ThisObject["Comment" + vNameIndex] = vCommentRow.Comments;
	
	// Create new group (BlockGroup)
	vCommentGroup = Items.Add("CommentGroup" + vNameIndex, Type("FormGroup"), Items.GroupMessage);
	vCommentGroup.Type = FormGroupType.UsualGroup;
	vCommentGroup.Representation = UsualGroupRepresentation.None;
	vCommentGroup.Group = ChildFormItemsGroup.Vertical;
	vCommentGroup.Title = Format(vCommentRow.Period, "DF='dd.MM.yyyy HH:mm'") + " - " + vCommentRow.Employee + 
	                      ?(ValueIsFilled(vCommentRow.MessageStatus), " - " + vCommentRow.MessageStatus, "");
	vCommentGroup.ToolTip = vCommentGroup.Title;
	vCommentGroup.ShowTitle = True;
	vCommentGroup.HorizontalStretch = True;
	
	vCommentField = Items.Add("CommentField"+vNameIndex, Type("FormField"), vCommentGroup);
	vCommentField.Type = FormFieldType.InputField;
	vCommentField.DataPath = "Comment" + vNameIndex;
	vCommentField.TitleLocation = FormItemTitleLocation.None;
	vCommentField.ToolTip = "";
	vCommentField.AutoMaxWidth = False;
	vcommentField.Enabled=vEnabled;
	
	If vEnabled Then
		
		// Delete Items
		If Not(Items.Find("DeletComment")=Undefined) Then
			vNumberDelete = Number(vNameIndex) - 1;
			Items.Delete(Items.DeletComment);
			Items["CommentGroup" + String(vNumberDelete)].Enabled = False;
		EndIf;
		
		
		// Create new Button (PrintEmployee)
		vPrintButton = Items.Add("DeletComment", Type("FormButton"), vCommentGroup);
		vPrintButton.Title = "";
		vPrintButton.Type = FormButtonType.UsualButton;
		vPrintButton.Enabled = True;
		vPrintButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
		vPrintButton.CommandName = "CommandDeletComment";
		vPrintButton.SkipOnInput = True;
		vNumberDelete = vNameIndex;
	EndIf;
EndProcedure //  AddNewItemsForms

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearanceAtServer()
	If ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.Type) Then
			Object.Type = Enums.MessageTypes.Task;
		EndIf;
	Else
		Object.ActivityStartTime = CurrentDate();
		Object.ActivityEndTime = Object.ActivityStartTime + 60 * 15;
	EndIf;
	If ValueIsFilled(Object.Type) And 
	   ValueIsFilled(Object.MessageStatus) And 
	   ValueIsFilled(Object.MessageStatus.Type) And
	   Object.MessageStatus.Type <> Object.Type Then
		Object.MessageStatus = Undefined;
	EndIf;
	If Object.Type = Enums.MessageTypes.Task Or Object.Type = Enums.MessageTypes.Message Then
		Items.GroupActivity.Visible = False;
		Items.GroupTask.Visible = True;
		Items.GroupMessage.Visible = True;
	ElsIf Object.Type = Enums.MessageTypes.Activity Then
		Items.GroupActivity.Visible = True;
		Items.GroupTask.Visible = False;
		Items.GroupMessage.Visible = True;
		If Object.ForEmployee <> Object.Author Then
			vEmployees = Object.ForEmployees.FindRows(New Structure("Employee", Object.Author));
			If vEmployees.Count() = 0 Then
				If Not ValueIsFilled(Object.ForEmployee) Then
					Object.ForEmployee = Object.Author;
				Else
					vNewEmployeesRow = Object.ForEmployees.Add();
					vNewEmployeesRow.Employee = Object.Author;
				EndIf;
			EndIf;
		EndIf;
	Else
		Items.GroupActivity.Visible = False;
		Items.GroupTask.Visible = False;
		Items.GroupMessage.Visible = False;
	EndIf;
	SetReservationTaskAreaAppearanceAtServer();
EndProcedure //  SetFormAppearanceAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetReservationTaskAreaAppearanceAtServer()
	If Object.Type = Enums.MessageTypes.Task And 
	   ValueIsFilled(Object.ByObject) And 
	  (TypeOf(Object.ByObject) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ByObject) = Type("DocumentRef.Reservation")) Then
		Items.ReservationTaskArea.Visible = True;
	Else
		Items.ReservationTaskArea.Visible = False;
	EndIf;
EndProcedure //  SetReservationTaskAreaAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteServer()
	If  vNumberDelete>0 Then
		Items.Delete(Items["CommentGroup" + String(vNumberDelete)]);
	EndIf;
	
	Obj = FormAttributeToValue("Object");
	Obj.Comments.Delete(vNumberDelete - 1);
	vTempArray = New Array;
	vTempArray.Add("Comment" + vNumberDelete);
	ChangeAttributes( , vTempArray);
	ValueToFormAttribute(Obj, "Object");
	
	vNumberDelete = vNumberDelete -1;
	vCommentGroup = Items.Find("CommentGroup" + String(vNumberDelete));
	If Not(vCommentGroup=Undefined) Then
		Object.MessageStatus = Object.Comments[vNumberDelete - 1].MessageStatus;
		If Object.Comments[vNumberDelete - 1].Employee = SessionParameters.CurrentUser Then
			vCommentGroup.Enabled = True;
			
			// Create new Button (PrintEmployee)
			vPrintButton = Items.Add("DeletComment", Type("FormButton"), vCommentGroup);
			vPrintButton.Title = "";
			vPrintButton.Type = FormButtonType.UsualButton;
			vPrintButton.Enabled = True;
			vPrintButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
			vPrintButton.CommandName = "CommandDeletComment";
			vPrintButton.SkipOnInput = True;
		EndIf;
	EndIf;	
EndProcedure //  DeleteServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ContactPersonOnChangeAtServer()
	If ValueIsFilled(Object.ContactPerson) Then
		If ValueIsFilled(Object.ByObject) And TypeOf(Object.ByObject) = Type("CatalogRef.Customers") Then
			vCPRow = Object.ByObject.ContactPersons.Find(Object.ContactPerson, "Client");
			If vCPRow <> Undefined Then
				Object.Position = vCPRow.Position;
				Object.Phone = vCPRow.Phone;
				Object.Phone2 = vCPRow.Phone2;
				Object.EMail = vCPRow.EMail;
			Else
				Object.Position = Object.ContactPerson.Position;
				Object.Phone = Object.ContactPerson.Phone;
				Object.Phone2 = Object.ContactPerson.Fax;
				Object.EMail = Object.ContactPerson.EMail;
			EndIf;
		Else
			Object.Position = Object.ContactPerson.Position;
			Object.Phone = Object.ContactPerson.Phone;
			Object.Phone2 = Object.ContactPerson.Fax;
			Object.EMail = Object.ContactPerson.EMail;
		EndIf;
	Else
		Object.Position = "";
		Object.Phone = "";
		Object.Phone2 = "";
		Object.EMail = "";
	EndIf;
EndProcedure //  ContactPersonOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ContactPersonStartChoiceAtServer(pCustomer)
	vCPList = New ValueList();
	If ValueIsFilled(pCustomer) And TypeOf(pCustomer) = Type("CatalogRef.Customers") Then
		For Each vCPRow In pCustomer.ContactPersons Do
			If ValueIsFilled(vCPRow.Client) Then
				vCPList.Add(vCPRow.Client, TrimAll(vCPRow.Client.FullName) + ?(IsBlankString(vCPRow.Position), "", ", " + TrimAll(vCPRow.Position)));
			EndIf;
		EndDo;
	EndIf;
	Return vCPList;
EndFunction //  ContactPersonStartChoiceAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure MessageTypeOnChangeAtServer()
	If ValueIsFilled(Object.MessageType) Then
		If ValueIsFilled(Object.MessageType.DefaultMessageStatus) Then
			Object.MessageStatus = Object.MessageType.DefaultMessageStatus;
			Object.IsClosed = Object.MessageStatus.IsClosed;
		EndIf;
		If ValueIsFilled(Object.MessageType.Department) Then
			Object.ForDepartment = Object.MessageType.Department;
			Object.ForDepartments.Clear();
		EndIf;
	EndIf;
EndProcedure //  MessageTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetMessageTypeListAtServer()
	vMessageTypeList = New ValueList();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	MessageTypes.Ref AS Ref
	|FROM
	|	Catalog.MessageTypes AS MessageTypes
	|WHERE
	|	(MessageTypes.Hotel = &qHotel
	|			OR MessageTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND MessageTypes.Type = &qType
	|	AND NOT MessageTypes.DeletionMark
	|
	|ORDER BY
	|	MessageTypes.SortCode";
	vQuery.SetParameter("qHotel", SessionParameters.CurrentHotel); 
	vQuery.SetParameter("qType", Object.Type);
	vResult = vQuery.Execute().Unload();
	vMessageTypeList.LoadValues(vResult.UnloadColumn("Ref"));
	Return vMessageTypeList;
EndFunction //  GetMessageTypeListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonAfterChoice(vUC, vExtraParams) Export
	If vUC <> Undefined Then
		Object.ContactPerson = vUC.Value;
		ContactPersonOnChange(Items.ContactPerson);
	EndIf;
EndProcedure //  ContactPersonAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetEmployeesListAtServer()
	vEmployeesList = New ValueList();
	vEmployees = cmGetAllEmployees(SessionParameters.CurrentHotel);	
	vEmployeesList.LoadValues(vEmployees.UnloadColumn("Employee"));
	If ValueIsFilled(Object.ForEmployee) Then
		vSPItem = vEmployeesList.FindByValue(Object.ForEmployee);
		If vSPItem <> Undefined Then
			vSPItem.Check = True;
		EndIf;
	EndIf;
	For Each vSPRow In Object.ForEmployees Do
		If ValueIsFilled(vSPRow.Employee) Then
			vSPItem = vEmployeesList.FindByValue(vSPRow.Employee);
			If vSPItem <> Undefined Then
				vSPItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vEmployeesList;
EndFunction //  GetEmployeesListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	SaveEmployeesAtServer(pValue);
	RefreshDataRepresentation();
	Modified = True;
EndProcedure //  EmployeesStartChoice_AfterInput

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveEmployeesAtServer(pEmployeesList)
	If ValueIsFilled(Object.ForEmployee) Then
		Object.ForEmployee = Catalogs.Employees.EmptyRef();
	EndIf;
	If Object.ForEmployees.Count() > 0 Then
		Object.ForEmployees.Clear();
	EndIf;
	If pEmployeesList.Count() > 0 Then
		vIsFirstItem = True;
		For Each vItem In pEmployeesList Do
			If vItem.Check Then
				If vIsFirstItem Then
					vIsFirstItem = False;
					Object.ForEmployee = vItem.Value;
				Else
					vSPRow = Object.ForEmployees.Add();
					vSPRow.Employee = vItem.Value;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Fill service packages presentation
	FillEmployeesPresentation();
EndProcedure //  SaveEmployeesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeesPresentation()
	// Service packages
	TEmployeesPresentation = "";
	If ValueIsFilled(Object.ForEmployee) Then
		TEmployeesPresentation = TrimAll(Object.ForEmployee);
	EndIf;
	For Each vEmployeeRow In Object.ForEmployees Do
		If ValueIsFilled(vEmployeeRow.Employee) Then
			If IsBlankString(TEmployeesPresentation) Then
				TEmployeesPresentation = TrimAll(vEmployeeRow.Employee);
			Else
				TEmployeesPresentation = TEmployeesPresentation + ", " + TrimAll(vEmployeeRow.Employee);
			EndIf;
		EndIf;
	EndDo;
EndProcedure //  FillEmployeesPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure ForEmployeeClearingAtServer()
	Object.ForEmployee = Catalogs.Employees.EmptyRef();
	Object.ForEmployees.Clear();
	// Fill service packages presentation
	FillEmployeesPresentation();
EndProcedure //  ForEmployeeClearingAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetDepartmentsListAtServer()
	vDepartmentsList = New ValueList();
	vDepartments = GetAllDepartments(SessionParameters.CurrentHotel);	
	vDepartmentsList.LoadValues(vDepartments.UnloadColumn("Department"));
	If ValueIsFilled(Object.ForDepartment) Then
		vItem = vDepartmentsList.FindByValue(Object.ForDepartment);
		If vItem <> Undefined Then
			vItem.Check = True;
		EndIf;
	EndIf;
	For Each vRow In Object.ForDepartments Do
		If ValueIsFilled(vRow.Department) Then
			vItem = vDepartmentsList.FindByValue(vRow.Department);
			If vItem <> Undefined Then
				vItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vDepartmentsList;
EndFunction //  GetDepartmentsListAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAllDepartments(pHotel)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Departments.Ref AS Department
	|FROM
	|	Catalog.Departments AS Departments
	|WHERE
	|	NOT Departments.DeletionMark
	|	AND NOT Departments.IsFolder
	|	AND (Departments.Hotel = &qHotel
	|			OR Departments.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	Departments.SortCode,
	|	Departments.Code";
	vQ.SetParameter("qHotel", pHotel);
	Return vQ.Execute().Unload();
EndFunction //  GetAllDepartments

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveDepartmentsAtServer(pDepartmentsList)
	If ValueIsFilled(Object.ForDepartment) Then
		Object.ForDepartment = Catalogs.Departments.EmptyRef();
	EndIf;
	If Object.ForDepartments.Count() > 0 Then
		Object.ForDepartments.Clear();
	EndIf;
	If pDepartmentsList.Count() > 0 Then
		vIsFirstItem = True;
		For Each vItem In pDepartmentsList Do
			If vItem.Check Then
				If vIsFirstItem Then
					vIsFirstItem = False;
					Object.ForDepartment = vItem.Value;
				Else
					vSPRow = Object.ForDepartments.Add();
					vSPRow.Department = vItem.Value;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Fill service packages presentation
	FillDepartmentsPresentation();
EndProcedure //  SaveDepartmentsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDepartmentsPresentation()
	// Service packages
	TDepartmentsPresentation = "";
	If ValueIsFilled(Object.ForDepartment) Then
		TDepartmentsPresentation = TrimAll(Object.ForDepartment);
	EndIf;
	For Each vDepartmentRow In Object.ForDepartments Do
		If ValueIsFilled(vDepartmentRow.Department) Then
			If IsBlankString(TDepartmentsPresentation) Then
				TDepartmentsPresentation = TrimAll(vDepartmentRow.Department);
			Else
				TDepartmentsPresentation = TDepartmentsPresentation + ", " + TrimAll(vDepartmentRow.Department);
			EndIf;
		EndIf;
	EndDo;
EndProcedure //  FillDepartmentsPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure ForDepartmentClearingAtServer()
	Object.ForDepartment = Catalogs.Departments.EmptyRef();
	Object.ForDepartments.Clear();
	// Fill service packages presentation
	FillDepartmentsPresentation();
EndProcedure //  ForDepartmentClearingAtServer

&AtClient
Procedure MessageTypeOnChange(Item)
	MessageTypeOnChangeAtServer();
EndProcedure

#EndRegion
