
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.LinkedQuestions.RowFilter = New FixedStructure("LinkedFeedbackQuestion", Undefined);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure QuestionsMandatoryOnChange(pItem)
	If Items.Questions.CurrentData <> Undefined and ValueIsFilled(Items.Questions.CurrentData.FeedbackQuestion) Then
		If NOT CheckQuestionAnswerNumberRestrictionFrom(Items.Questions.CurrentData.FeedbackQuestion) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'У обязательного вопроса с числовым ответом ограничение не должно начинаться с 0!'")); //#Translate
			Items.Questions.CurrentData.Mandatory = False;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure QuestionsFeedbackQuestionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	For each vRow in Object.Questions Do
		If vRow.FeedbackQuestion = pSelectedValue Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Such a question already exists in the survey!'; de = 'Eine solche Frage existiert bereits in der Umfrage!'; ru = 'Такой вопрос уже есть в опросе!'"));
			pSelectedValue = Undefined;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LinkedQuestionsFeedbackQuestionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	vCurrentQuestionRow = Items.Questions.CurrentData;
	For each vRow in Object.LinkedQuestions Do
		If vCurrentQuestionRow.FeedbackQuestion = pSelectedValue Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You can not connect the question with itrself!'; de = 'Sie können die Frage nicht mit sich selbst verbinden!'; ru = 'Нельзя связать вопрос с самим собой!'"));
			pSelectedValue = Undefined;
		EndIf;
		If vCurrentQuestionRow.FeedbackQuestion = vRow.LinkedFeedbackQuestion and vRow.FeedbackQuestion = pSelectedValue Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Such a question already exists in the survey!'; de = 'Eine solche Frage existiert bereits in der Umfrage!'; ru = 'Такой вопрос уже есть в опросе!'"));
			pSelectedValue = Undefined;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure QuestionsOnActivateRow(pItem)
	If Items.Questions.CurrentData <> Undefined and ValueIsFilled(Items.Questions.CurrentData.FeedbackQuestion) Then
		Items.LinkedQuestions.RowFilter = New FixedStructure("LinkedFeedbackQuestion", Items.Questions.CurrentData.FeedbackQuestion);
	Else
		Items.LinkedQuestions.RowFilter = New FixedStructure("LinkedFeedbackQuestion", Undefined);	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LinkedQuestionsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	If Items.Questions.CurrentData <> Undefined and ValueIsFilled(Items.Questions.CurrentData.FeedbackQuestion) Then 
		vNewRow = Object.LinkedQuestions.Add();
		vNewRow.LinkedFeedbackQuestion = Items.Questions.CurrentData.FeedbackQuestion;
		vAnswerType = GetAnswerType(Items.Questions.CurrentData.FeedbackQuestion);
		If vAnswerType = "Boolean" Then
			vNewRow.AnswerForLink = False;
		ElsIf vAnswerType = "String" Then
			vNewRow.AnswerForLink = "";
		ElsIf vAnswerType = "Number" Then
			vNewRow.AnswerForLink = 0;
		ElsIf vAnswerType = "List" Then
			vNewRow.AnswerForLink = "";
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure QuestionsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = pClone;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LinkedQuestionsOnActivateRow(pItem)
	If Items.LinkedQuestions.CurrentData <> Undefined and ValueIsFilled(Items.LinkedQuestions.CurrentData.LinkedFeedbackQuestion) Then 
		vAnswerType = GetAnswerType(Items.LinkedQuestions.CurrentData.LinkedFeedbackQuestion);
		If vAnswerType = "List" or vAnswerType = "Boolean" Then
			Items.LinkedQuestionsAnswerForLink.TextEdit = False;
			Items.LinkedQuestionsAnswerForLink.ChoiceButton = True;
		Else
			Items.LinkedQuestionsAnswerForLink.TextEdit = True;
			Items.LinkedQuestionsAnswerForLink.ChoiceButton = False;	
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LinkedQuestionsAnswerForLinkStartChoice(pItem, pChoiceData, pStandardProcessing)
	If Items.LinkedQuestions.CurrentData <> Undefined and ValueIsFilled(Items.LinkedQuestions.CurrentData.LinkedFeedbackQuestion) Then
		pStandardProcessing = False;
		vAnswerType = GetAnswerType(Items.LinkedQuestions.CurrentData.LinkedFeedbackQuestion);
		If vAnswerType = "List" Then 
			pChoiceData = GetAnswers(Items.LinkedQuestions.CurrentData.LinkedFeedbackQuestion);
		ElsIf vAnswerType = "Boolean" Then
			pChoiceData = New ValueList;
			pChoiceData.Add(True);
			pChoiceData.Add(False);
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LinkedQuestionsMandatoryOnChange(pItem)
	If Items.LinkedQuestions.CurrentData <> Undefined and ValueIsFilled(Items.LinkedQuestions.CurrentData.FeedbackQuestion) Then
		If NOT CheckQuestionAnswerNumberRestrictionFrom(Items.LinkedQuestions.CurrentData.FeedbackQuestion) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'У обязательного вопроса с числовым ответом ограничение не должно начинаться с 0!'")); //#Translate
			Items.LinkedQuestions.CurrentData.Mandatory = False;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Catalog.Surveys.Form.PrintForm", New Structure("Ref", Object.Ref));
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAnswerType(pQuestion)
	If pQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
		Return "Boolean";
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.String Then
		Return "String";
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.Number Then
		Return "Number";
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.List Then 
		Return "List";
	EndIf;
	Return Undefined;	
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckQuestionAnswerNumberRestrictionFrom(pFeedbackQuestion)
	vSuccess = True;	
	If pFeedbackQuestion.AnswerType = Enums.AnswerTypes.Number Then
		If pFeedbackQuestion.AnswerNumberRestrictionFrom = 0 Then
			vSuccess = False;	
		EndIf;
	EndIf;
	Return vSuccess;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAnswers(pQuestion)
	vResult = New ValueList;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	FeedbackQuestionsAnswerVariants.AnswerText
		|FROM
		|	Catalog.FeedbackQuestions.AnswerVariants AS FeedbackQuestionsAnswerVariants
		|WHERE
		|	FeedbackQuestionsAnswerVariants.Ref = &qQuestion";
	
	vQuery.SetParameter("qQuestion", pQuestion);
	
	vQueryResult = vQuery.Execute().Select();
	While vQueryResult.Next() Do
		vResult.Add(vQueryResult.AnswerText);	
	EndDo;
	Return vResult
EndFunction

#EndRegion    
