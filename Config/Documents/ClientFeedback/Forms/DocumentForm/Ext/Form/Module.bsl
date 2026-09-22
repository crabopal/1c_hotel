
#Region FormEventHandlers

// ------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If NOT ValueIsFilled(Object.Ref) Then
		vObj = FormAttributeToValue("Object");
		vObj.pmFillAttributesWithDefaultValues();
		ValueToFormAttribute(vObj, "Object");
		LoadSurveyQuestions();
	EndIf;
	If Not ValueIsFilled(Object.Survey) Then
		CurrentItem = Items.Survey;
	ElsIf Not ValueIsFilled(Object.ParentDoc) Then
		CurrentItem = Items.Room;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure SurveyOnChange(pItem)
	LoadSurveyQuestions();
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure AnswersOnActivateRow(pItem)
	If Items.Answers.CurrentData <> Undefined and ValueIsFilled(Items.Answers.CurrentData.FeedbackQuestion) Then
		If isAnswerTypeList(Items.Answers.CurrentData.FeedbackQuestion) or isAnswerTypeBoolean(Items.Answers.CurrentData.FeedbackQuestion) Then
			Items.AnswersAnswer.ChoiceButton = True;
		Else
			Items.AnswersAnswer.ChoiceButton = False;	
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure AnswersAnswerStartChoice(pItem, pChoiceData, pStandardProcessing)
	If isAnswerTypeList(Items.Answers.CurrentData.FeedbackQuestion) Then
		pStandardProcessing = False;
		pChoiceData = GetFeedbackQuestionAnswerList(Items.Answers.CurrentData.FeedbackQuestion);
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure SurveyStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure;
	vParams.Insert("ChoiceMode", True);
	If ValueIsFilled(Object.Hotel) Then
		vParams.Insert("Hotel", Object.Hotel); 	
	EndIf;	
	OpenForm("Catalog.Surveys.ChoiceForm", vParams, pItem,,,,, FormWindowOpeningMode.LockOwnerWindow);	
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure ParentDocOnChange(pItem)
	ParentDocOnChangeAtServer();
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure AnswersBeforeEditEnd(pItem, pNewRow, pCancelEdit, pCancel) 
	vCurData = Items.Answers.CurrentData;
	If vCurData <> Undefined Then
		vMessage = "";
		pCancel = Not AnswersOnEditEndAtServer(vCurData.FeedbackQuestion, vCurData.Answer, vMessage);
		If pCancel Then
			vUM 		= New UserMessage();
			vUM.Field 	= "Object.Answers[" + Items.Answers.CurrentData.GetID() + "].Answer";
			vUM.Text 	= vMessage;
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure // AnswersBeforeEditEnd

// ------------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(Item)
	RoomOnChangeAtServer();
EndProcedure // RoomOnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	ClientOnChangeAtServer();
EndProcedure // ClientOnChange

#EndRegion

#Region Private

// ------------------------------------------------------------------------------
&AtServer
Procedure LoadSurveyQuestions()
	If ValueIsFilled(Object.Survey) Then
		If Object.Answers.Count() = 0 Then
			For each vQuestion in Object.Survey.Questions Do
				vNewRow 					= Object.Answers.Add();
				vNewRow.FeedbackQuestion 	= vQuestion.FeedbackQuestion;
				If vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.String Then
					vNewRow.Answer			= "";
				ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Number Then
					vNewRow.Answer			= 0;
				ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
					vNewRow.Answer			= False;
				ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.List Then
					vNewRow.Answer			= Undefined;
				EndIf;			
			EndDo;
		Else
			//Delete questions from another survey
			vClearArray = New Array;
			For each vAnswer in Object.Answers Do
				vFound = False;
				For each vQuestion in Object.Survey.Questions Do
					If vAnswer.FeedbackQuestion =  vQuestion.FeedbackQuestion Then
						vFound = True;
					EndIf;
				EndDo;
				vClearArray.Add(vAnswer);
			EndDo;
			For each vRow in vClearArray Do
				Object.Answers.Delete(vRow);
			EndDo;
			vAnswer 	= Undefined;
			vQuestion 	= Undefined;
			vClearArray = Undefined;
			
			//Add new questions
			For each vQuestion in Object.Survey.Questions Do
				vFound = False;
				For each vAnswer in Object.Answers Do	
					If vAnswer.FeedbackQuestion =  vQuestion.FeedbackQuestion Then
						vFound = True;
					EndIf;
				EndDo;
				If NOT vFound Then
					vNewRow 					= Object.Answers.Add();
					vNewRow.FeedbackQuestion 	= vQuestion.FeedbackQuestion;
					If vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.String Then
						vNewRow.Answer			= "";
					ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Number Then
                    	vNewRow.Answer			= 0;
					ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
                    	vNewRow.Answer			= False;
					ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.List Then
                    	vNewRow.Answer			= Undefined;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------
&AtServerNoContext
Function isAnswerTypeList(pFeedbackQuestion)
	If pFeedbackQuestion.AnswerType = Enums.AnswerTypes.List Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

// ------------------------------------------------------------------------------
&AtServerNoContext
Function isAnswerTypeBoolean(pFeedbackQuestion)
	If pFeedbackQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

// ------------------------------------------------------------------------------
&AtServerNoContext
Function GetFeedbackQuestionAnswerList(pFeedbackQuestion)
	vResult = New ValueList;
	For each vAnswer in pFeedbackQuestion.AnswerVariants Do
		vResult.Add(vAnswer.AnswerText);	
	EndDo;
	Return vResult;
EndFunction

// ------------------------------------------------------------------------------
&AtServer
Procedure ParentDocOnChangeAtServer()
	If ValueIsFilled(Object.ParentDoc) Then
		vObj = FormAttributeToValue("Object");
		vObj.Fill(Object.ParentDoc);
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ParentDocOnChangeAtServer

// ------------------------------------------------------------------------------
&AtServerNoContext
Function AnswersOnEditEndAtServer(pQuestion, pAnswer, rMessage = "")
	vOK = True;
	rMessage = "";
	If pQuestion.AnswerType = Enums.AnswerTypes.Number Then
		If pAnswer < pQuestion.AnswerNumberRestrictionFrom Or 
		   pAnswer > pQuestion.AnswerNumberRestrictionTo And pQuestion.AnswerNumberRestrictionTo <> 0 Then
			vOK = False;
			rMessage = NStr("en='The answer does not fall within the allowed range: '; ru='Ответ не попадает в разрешенный диапазон: '; de='Die Antwort fällt nicht in den zulässigen Bereich: '") + Format(pQuestion.AnswerNumberRestrictionFrom, "NZ=; NG=") + " - " + Format(pQuestion.AnswerNumberRestrictionTo, "NZ=; NG=");
		EndIf;
	EndIf;
	Return vOK;
EndFunction // AnswersOnEditEndAtServer

// ------------------------------------------------------------------------------
// Fill parent document and client
// ------------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	Object.ParentDoc = Undefined;
	Object.Client = Undefined;
	If ValueIsFilled(Object.Room) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 6
		|	Accommodation.Ref,
		|	Accommodation.Guest
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Room = &qRoom
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.Guest <> &qEmptyClient
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.Posted
		|
		|ORDER BY
		|	Accommodation.CheckInDate DESC,
		|	Accommodation.AccommodationType.SortCode";
		vQry.SetParameter("qRoom", Object.Room);
		vQry.SetParameter("qHotel", Object.Room.Owner);
		vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vDocsRow = vDocs.Get(0);
			Object.ParentDoc = vDocsRow.Ref;
			Object.Client = vDocsRow.Guest;
			
			Clients.Clear();
			Items.Client.ChoiceList.Clear();
			Items.Client.ListChoiceMode = True;
			For Each vDocsRow In vDocs Do
				vClientsRow = Clients.Add();
				vClientsRow.ParentDoc = vDocsRow.Ref;
				vClientsRow.Client = vDocsRow.Guest;
				
				Items.Client.ChoiceList.Add(vDocsRow.Guest);
			EndDo;
		Else
			Clients.Clear();
			Items.Client.ChoiceList.Clear();
			Items.Client.ListChoiceMode = True;
		EndIf;
	Else
		Clients.Clear();
		Items.Client.ChoiceList.Clear();
		Items.Client.ListChoiceMode = False;
	EndIf;
EndProcedure // RoomOnChangeAtServer

// ------------------------------------------------------------------------------
&AtServer
Procedure FillClientLastAccommodation()
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref,
	|	Accommodation.Room
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Guest = &qClient
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Posted
	|
	|ORDER BY
	|	Accommodation.CheckInDate DESC,
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qClient", Object.Client);
	vQry.SetParameter("qHotel", Object.Hotel);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		For Each vDocsRow In vDocs Do
			Object.ParentDoc = vDocsRow.Ref;
			Object.Room = vDocsRow.Room;
			Break;
		EndDo;
	Else
		Object.ParentDoc = Undefined;
		Object.Room = Undefined;
	EndIf;
EndProcedure // FillClientLastAccommodation

// ------------------------------------------------------------------------------
&AtServer
Procedure ClientOnChangeAtServer()
	Object.ParentDoc = Undefined;
	If ValueIsFilled(Object.Client) Then
		For Each vClientsRow In Clients Do
			If Object.Client = vClientsRow.Client Then
				Object.ParentDoc = vClientsRow.ParentDoc;
				Break;
			EndIf;
		EndDo;
		If Not ValueIsFilled(Object.ParentDoc) Then
			Clients.Clear();
			Items.Client.ChoiceList.Clear();
			Items.Client.ListChoiceMode = False;
			// Try to find last client's accommodation
			FillClientLastAccommodation();
		EndIf;
	EndIf;
EndProcedure // ClientOnChangeAtServer

#EndRegion
