
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		Obj.DataProcessor = Catalogs.DataProcessors.Feedback;	
	EndIf;
	
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	Surveys.Parameters.SetParameterValue("qHotel", SessionParameters.CurrentHotel);
	Surveys.Parameters.SetParameterValue("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	
	Survey = Undefined;
	For each vUserRow in Object.UsersSurveys Do
		If vUserRow.User = SessionParameters.CurrentUser Then
			Survey = vUserRow.Survey;
			Break;
		EndIf;
	EndDo;
	
	GenerateSurvey();	
EndProcedure

&AtServer
Procedure GenerateSurvey()
	If ValueIsFilled(Survey) Then
		Items.Surveys.Visible 			= False;
		Items.Group_Survey.Visible 		= True;
		Items.Group_Recorder.Visible 	= True;
		
		vSurveyGroup = Items.Group_Questions;
		
		vTitle 	= "";
		vHeader = "";
		vFooter = "";
		
		vQueryQuestions = New Query;
		vQueryQuestions.Text = 
		"SELECT
		|	SurveysQuestions.Ref.Description AS SurveyDescription,
		|	SurveysQuestions.Ref.HeaderText AS HeaderText,
		|	SurveysQuestions.Ref.FooterText AS FooterText,
		|	FeedbackQuestions.QuestionText AS Question,
		|	SurveysQuestions.Mandatory AS Mandatory,
		|	FeedbackQuestions.AnswerType AS AnswerType,
		|	FeedbackQuestions.AnswerNumberRestrictionFrom AS AnswerNumberRestrictionFrom,
		|	FeedbackQuestions.AnswerNumberRestrictionTo AS AnswerNumberRestrictionTo,
		|	FeedbackQuestions.AnswerVariants.(
		|		AnswerText AS AnswerText,
		|		AnswerWeight AS AnswerWeight
		|	) AS AnswerVariants,
		|	FeedbackQuestions.Ref AS Ref,
		|	FeedbackQuestions.AnswerListMaxVariants AS AnswerListMaxVariants
		|FROM
		|	Catalog.Surveys.Questions AS SurveysQuestions
		|		LEFT JOIN Catalog.FeedbackQuestions AS FeedbackQuestions
		|		ON SurveysQuestions.FeedbackQuestion = FeedbackQuestions.Ref
		|WHERE
		|	NOT SurveysQuestions.FeedbackQuestion.DeletionMark
		|	AND SurveysQuestions.Ref = &qSurvey
		|
		|ORDER BY
		|	SurveysQuestions.LineNumber";
		
		vQueryQuestions.SetParameter("qSurvey", Survey);
		vQueryResultQuestions = vQueryQuestions.Execute().Select();
		
		vQueryLinkedQuestions = New Query;
		vQueryLinkedQuestions.Text = 
		"SELECT
		|	FeedbackQuestions.QuestionText AS Question,
		|	SurveysLinkedQuestions.Mandatory AS Mandatory,
		|	FeedbackQuestions.AnswerType AS AnswerType,
		|	FeedbackQuestions.AnswerNumberRestrictionFrom AS AnswerNumberRestrictionFrom,
		|	FeedbackQuestions.AnswerNumberRestrictionTo AS AnswerNumberRestrictionTo,
		|	FeedbackQuestions.AnswerVariants.(
		|		AnswerText AS AnswerText,
		|		AnswerWeight AS AnswerWeight
		|	) AS AnswerVariants,
		|	FeedbackQuestions.Ref AS Ref,
		|	FeedbackQuestions.AnswerListMaxVariants AS AnswerListMaxVariants,
		|	SurveysLinkedQuestions.LinkedFeedbackQuestion AS LinkedFeedbackQuestion,
		|	SurveysLinkedQuestions.AnswerForLink AS AnswerForLink
		|FROM
		|	Catalog.Surveys.LinkedQuestions AS SurveysLinkedQuestions
		|		LEFT JOIN Catalog.FeedbackQuestions AS FeedbackQuestions
		|		ON SurveysLinkedQuestions.FeedbackQuestion = FeedbackQuestions.Ref
		|WHERE
		|	NOT SurveysLinkedQuestions.FeedbackQuestion.DeletionMark
		|	AND SurveysLinkedQuestions.Ref = &qSurvey
		|
		|ORDER BY
		|	AnswerForLink";
		
		vQueryLinkedQuestions.SetParameter("qSurvey", Survey);
		vQueryResultLinkedQuestions = vQueryLinkedQuestions.Execute().Unload();
	
		While vQueryResultQuestions.Next() Do
			vTitle	= vQueryResultQuestions.SurveyDescription;
			vHeader = vQueryResultQuestions.HeaderText;
			vFooter = vQueryResultQuestions.FooterText;
			
			vRow 								= Questions.Add();
			vRow.Question 						= vQueryResultQuestions.Ref;
			vRow.LinkedFeedbackQuestion 		= Undefined;
			vRow.QuestionText 					= vQueryResultQuestions.Question;
			vRow.AnswerType 					= vQueryResultQuestions.AnswerType;
			vRow.AnswerNumberRestrictionFrom 	= vQueryResultQuestions.AnswerNumberRestrictionFrom;
			vRow.AnswerNumberRestrictionTo 		= vQueryResultQuestions.AnswerNumberRestrictionTo;
			vRow.Mandatory						= vQueryResultQuestions.Mandatory;
			vRow.AnswerListMaxVariants			= vQueryResultQuestions.AnswerListMaxVariants;
			vRow.AnswerForLink					= Undefined;
			vRow.AnswerID						= 0;
			vRow.AnswerVariants.Load(vQueryResultQuestions.AnswerVariants.Unload());
			vLinkedQuestions = vQueryResultLinkedQuestions.FindRows(New Structure("LinkedFeedbackQuestion", vQueryResultQuestions.Ref));
			vAnswerID 	= 0;
			vPrevAnswer = Undefined;
			For each vLinkedQuestion in vLinkedQuestions Do
				If vPrevAnswer <> vLinkedQuestion.AnswerForLink Then
					vAnswerID = vAnswerID + 1;
				EndIf;

				vRow 								= Questions.Add();
				vRow.Question 						= vLinkedQuestion.Ref;
				vRow.LinkedFeedbackQuestion 		= vQueryResultQuestions.Ref;
				vRow.QuestionText 					= vLinkedQuestion.Question;
				vRow.AnswerType 					= vLinkedQuestion.AnswerType;
				vRow.AnswerNumberRestrictionFrom 	= vLinkedQuestion.AnswerNumberRestrictionFrom;
				vRow.AnswerNumberRestrictionTo 		= vLinkedQuestion.AnswerNumberRestrictionTo;
				vRow.Mandatory						= vLinkedQuestion.Mandatory;
				vRow.AnswerListMaxVariants			= vLinkedQuestion.AnswerListMaxVariants;
				vRow.AnswerForLink					= vLinkedQuestion.AnswerForLink;
				vRow.AnswerID 						= vAnswerID;
				For each vLinkedAnswerVariant in vLinkedQuestion.AnswerVariants Do
					vAnswerRow = vRow.AnswerVariants.Add();
					FillPropertyValues(vAnswerRow, vLinkedAnswerVariant); 
				EndDo;
				vPrevAnswer = vLinkedQuestion.AnswerForLink;					
			EndDo;
		EndDo;
		
		i = 0;
		vParentQuestionId = 0;
		vMainQuestionsCount = 0;
		vQuestionGroup = Undefined;
		vGroupTable = New ValueTable;
		vGroupTable.Columns.Add("Group");
		vGroupTable.Columns.Add("ID");
		For each vQuestion in Questions Do
			If vQuestion.LinkedFeedbackQuestion = Catalogs.FeedbackQuestions.EmptyRef() Then
				vGroupTable.Clear();
				vMainQuestionsCount = vMainQuestionsCount + 1;
				vQuestionGroup = OutputQuestion(vQuestion, i, vSurveyGroup, String(vMainQuestionsCount));
				j = 0;
				vParentQuestionId = i;			
			ElsIf vQuestionGroup <> Undefined Then
				vLinkedQuestionGroup = Undefined;
				vFound = False;
				For each vGroupRow in vGroupTable Do
					If vGroupRow.ID	= vQuestion.AnswerID Then
						vLinkedQuestionGroup = vGroupRow.Group;
						vFound = True;
						Break;
					EndIf;
				EndDo;
				If NOT vFound Then
					j = 0;
				EndIf;
				vLinkedQuestionGroup = OutputQuestion(vQuestion, i, vSurveyGroup, String(vMainQuestionsCount) + "." + String(j + 1), vQuestionGroup, vLinkedQuestionGroup, vParentQuestionId);
				If NOT vFound Then
					vGroupRow 		= vGroupTable.Add();
					vGroupRow.Group = vLinkedQuestionGroup;
					vGroupRow.ID	= vQuestion.AnswerID;
				EndIf;
				j = j + 1;
			Else
				tcCommonFunctionOnClientServer.TextMessage("Error in generating survey!");				
			EndIf;
			i = i + 1;
		EndDo;
		
		If ValueIsFilled(vTitle) Then
			Title = vTitle; 
		EndIf;
		
		If ValueIsFilled(vHeader) Then
			Items.Header.Title 	= vHeader;
		Else
			Items.Header.Visible = False;
		EndIf;
		
		If ValueIsFilled(vFooter) Then
			Items.Footer.Title = vFooter;
		Else
			Items.Footer.Visible = False;
		EndIf;
	Else
		Items.Surveys.Visible 		= True;
		Items.Group_Survey.Visible 	= False;
		Items.Group_Recorder.Visible 	= False;
	EndIf;
EndProcedure

&AtServer
Function OutputQuestion(pQuestion, pQuestionCount, pSurveyGroup, pQuestinNumber,  pQuestionGroup = Undefined, pLinkedQuestionGroup = Undefined, pLinkedQuestionID = Undefined)
	
	If pQuestionGroup <> Undefined and ValueIsFilled(pQuestion.LinkedFeedbackQuestion) and pLinkedQuestionGroup = Undefined Then
		vParams = New Structure("Type, Group, Representation, ShowTitle, Title, TitleFont, DisplayImportance, Visible", 
		FormGroupType.UsualGroup, ChildFormItemsGroup.Vertical, UsualGroupRepresentation.None, False, 
		"", New Font(pSurveyGroup.TitleFont,,,True), DisplayImportance.High, False);
		
		vLinkedQuestionGroup = tcOnServer.cmCreateItem(ThisForm , pQuestionGroup, "LinkedQuestion_ID" + pLinkedQuestionID + "_Link" + pQuestion.AnswerID, "FormGroup", vParams);
	ElsIf pLinkedQuestionGroup <> Undefined Then
		vLinkedQuestionGroup = pLinkedQuestionGroup;	
	Else
		vLinkedQuestionGroup = Undefined;
	EndIf;

	//Question №i group
	vQuestionTitle = cmNStr("en = 'Question №'; de = 'Frage №'; ru = 'Вопрос №'", SessionParameters.CurrentLanguage) + pQuestinNumber + ?(pQuestion.Mandatory,"*","");
	vParams = New Structure("Type, Group, Representation, ShowTitle, Title, TitleFont, DisplayImportance", 
	FormGroupType.UsualGroup, ChildFormItemsGroup.Vertical, UsualGroupRepresentation.StrongSeparation, True, 
	vQuestionTitle, New Font(pSurveyGroup.TitleFont,,,True), DisplayImportance.High);
	If vLinkedQuestionGroup = Undefined Then 
		vQuestionGroup = tcOnServer.cmCreateItem(ThisForm , pSurveyGroup, "Question_ID" + pQuestionCount, "FormGroup", vParams);
	Else
		vQuestionGroup = tcOnServer.cmCreateItem(ThisForm , vLinkedQuestionGroup, "Question_ID" + pQuestionCount, "FormGroup", vParams);
	EndIf;
	
	//Question text
	vParams = New Structure("Type, Title, HorizontalStretch", FormDecorationType.Label, pQuestion.QuestionText, True);
	tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "Question_ID" + pQuestionCount, "FormDecoration", vParams);
	
	If pQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
		pQuestion.SelectedAnswerBoolean = 9999;
		
		//Group for tumbler right align on mobile client
		vParams = New Structure("Type, Group, Representation, ShowTitle, TitleFont, DisplayImportance, ShowTitle", 
		FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupRepresentation.None, 
		True, New Font(pSurveyGroup.TitleFont,,,True), DisplayImportance.High, False);
		vBooleanGroup = tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "QuestionBoolean_ID" + pQuestionCount, "FormGroup", vParams);
		
		//Label with horizontal stretch and left align. On mobile client tumbler always left alligned otherwise
		vParams = New Structure("Type, Title, HorizontalStretch, HorizontalAlignInGroup", FormDecorationType.Label, "", True, ItemHorizontalLocation.Left);
		tcOnServer.cmCreateItem(ThisForm , vBooleanGroup, "QuestionBooleanLabel_ID" + pQuestionCount, "FormDecoration", vParams);
		
		//Answer Tumbler
		vParams = New Structure("Type, TitleLocation, DataPath, RadioButtonType, HorizontalAlignInGroup, SetActionOnChange, ItemHeight", FormFieldType.RadioButtonField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].SelectedAnswerBoolean", RadioButtonType.Tumbler, ItemHorizontalLocation.Right, "AnswerField_OnChange", 2);
		vRadioButton = tcOnServer.cmCreateItem(ThisForm , vBooleanGroup, "Question_ID" + pQuestionCount, "FormField", vParams);
		vRadioButton.ChoiceList.Add(0,cmNStr("en = 'No'; de = 'Nein'; ru = 'Нет'", SessionParameters.CurrentLanguage));
		vRadioButton.ChoiceList.Add(1,cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", SessionParameters.CurrentLanguage));
		
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.String Then
		//Answer string input field
		vParams = New Structure("Type, TitleLocation, DataPath, HorizontalStretch, MultiLine, SetActionOnChange", FormFieldType.InputField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].SelectedAnswerString", True, True, "AnswerField_OnChange");
		tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "Question_ID" + pQuestionCount, "FormField", vParams);
		
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.Number Then
		vRestrictionCount = pQuestion.AnswerNumberRestrictionTo - pQuestion.AnswerNumberRestrictionFrom;
		If vRestrictionCount > 0 and vRestrictionCount < 10 Then
			//Group for tumbler right align on mobile client
			vParams = New Structure("Type, Group, Representation, ShowTitle, TitleFont, DisplayImportance, ShowTitle", 
			FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupRepresentation.None, 
			True, New Font(pSurveyGroup.TitleFont,,,True), DisplayImportance.High, False);
			vNumberGroup = tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "QuestionBoolean_ID" + pQuestionCount, "FormGroup", vParams);
			
			//Label with horizontal stretch and left align. On mobile client tumbler always left alligned otherwise
			vParams = New Structure("Type, Title, HorizontalStretch, HorizontalAlignInGroup", FormDecorationType.Label, "", True, ItemHorizontalLocation.Left);
			tcOnServer.cmCreateItem(ThisForm , vNumberGroup, "QuestionBooleanLabel_ID" + pQuestionCount, "FormDecoration", vParams);
			
			//Answer Tumbler
			vParams = New Structure("Type, TitleLocation, DataPath, RadioButtonType, HorizontalAlignInGroup, EqualColumnsWidth, SetActionOnChange, ItemHeight", FormFieldType.RadioButtonField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].SelectedAnswerNumber", RadioButtonType.Tumbler, ItemHorizontalLocation.Right, True, "AnswerField_OnChange", 2);
			vRadioButton = tcOnServer.cmCreateItem(ThisForm , vNumberGroup, "Question_ID" + pQuestionCount, "FormField", vParams);
			
			vRestrictionCount = pQuestion.AnswerNumberRestrictionFrom;
			While vRestrictionCount <= pQuestion.AnswerNumberRestrictionTo Do
				vRadioButton.ChoiceList.Add(vRestrictionCount, "  " + vRestrictionCount);
				vRestrictionCount = vRestrictionCount + 1;
			EndDo;
		Else
			//Answer number input field with spin buttons
			vParams = New Structure("Type, TitleLocation, DataPath, HorizontalStretch, SpinButton, HorizontalAlignInGroup, HorizontalStretch, SetActionOnChange", FormFieldType.InputField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].SelectedAnswerNumber", False, True, ItemHorizontalLocation.Right, True, "AnswerField_OnChange");
			tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "Question_ID" + pQuestionCount, "FormField", vParams);
		EndIf;	
	ElsIf pQuestion.AnswerType = Enums.AnswerTypes.List Then
		If pQuestion.AnswerListMaxVariants = 1 Then
			//If only 1 variant mast be choosen then radio button
			vParams = New Structure("Type, TitleLocation, DataPath, RadioButtonType, ColumnsCount, HorizontalAlignInGroup, SetActionOnChange", FormFieldType.RadioButtonField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].SelectedAnswerString", RadioButtonType.RadioButton, 1, ItemHorizontalLocation.Right, "AnswerField_OnChange");
			vRadioButton = tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "Question_ID" + pQuestionCount, "FormField", vParams);
			For each vAnswerVariant in pQuestion.AnswerVariants Do
				vRadioButton.ChoiceList.Add(vAnswerVariant.AnswerText);
			EndDo;
		Else
			//Checkboxes for multiple choices
			j = 0;
			For each vAnswerVariant in pQuestion.AnswerVariants Do
				//Answer variant group
				vParams 		= New Structure("Type, Group, Representation, ShowTitle", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupRepresentation.None, False);
				vAnswerGroup 	= tcOnServer.cmCreateItem(ThisForm , vQuestionGroup, "AnswerVariant_ID" + pQuestionCount + "_" + j, "FormGroup", vParams);
				
				//Answer string
				vParams = New Structure("Type, Title, HorizontalStretch", FormDecorationType.Label, vAnswerVariant.AnswerText, True);
				tcOnServer.cmCreateItem(ThisForm , vAnswerGroup, "AnswerVariant_ID" + pQuestionCount + "_" + j, "FormDecoration", vParams);
				
				//Answer checkbox
				vParams = New Structure("Type, TitleLocation, DataPath, SetActionOnChange", FormFieldType.CheckBoxField, FormItemTitleLocation.None, "Questions[" + pQuestionCount + "].AnswerVariants[" + j + "].Selected", "AnswerField_OnChange");
				tcOnServer.cmCreateItem(ThisForm , vAnswerGroup, "AnswerVariant_ID" + pQuestionCount + "_" + j, "FormField", vParams);
				
				j = j + 1;
			EndDo;
		EndIf;
	EndIf;
	
	If vLinkedQuestionGroup <> Undefined Then
		vQuestionGroup = vLinkedQuestionGroup;
	EndIf;
	
	Return vQuestionGroup;
EndFunction

&AtClient
Procedure Reset(pCommand)
	RecorderDocument = Undefined;
	For each vQuestion in Questions Do
		vQuestion.SelectedAnswerBoolean = 9999;
		vQuestion.SelectedAnswerString 	= "";
		vQuestion.SelectedAnswerNumber 	= 0;
		vQuestion.SelectedAnswerWeight 	= 0;
		For each vAnswerVariant in vQuestion.AnswerVariants Do
			vAnswerVariant.Selected = False;	
		EndDo;
	EndDo;
	For each vItem in Items Do
		If TypeOf(vItem) = Type("FormGroup") Then
			If StrFind(vItem.Name, "FormGroupLinkedQuestion_ID") > 0 Then
				vItem.Visible = False;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure Finish(pCommand)
	vSuccess = Finish_AtServer();
	If vSuccess Then
		Reset(Undefined);
	EndIf;
EndProcedure

&AtServer
Function Finish_AtServer()
	vSuccess = True;
	vThereAreAnswers = False;
	i = 0;
	j = 0;
	For each vQuestion in Questions Do
		vLinkedQuestionIsActive = False;
		If ValueIsFilled(vQuestion.LinkedFeedbackQuestion) Then
			Try
				vLinkedItemGroup = Items.Find("FormGroupLinkedQuestion_ID" + j + "_Link" + vQuestion.AnswerID);
				vLinkedQuestionIsActive = vLinkedItemGroup.Visible;
			Except
				vLinkedQuestionIsActive = False;
			EndTry;
		EndIf;
		vQuestionTitle = Items.Find("FormGroupQuestion_ID" + i).Title;
		
		If NOT ValueIsFilled(vQuestion.LinkedFeedbackQuestion) or vLinkedQuestionIsActive Then 
			If vQuestion.AnswerType = Enums.AnswerTypes.Number Then
				If vQuestion.SelectedAnswerNumber <> 0 Then
					If vQuestion.SelectedAnswerNumber < vQuestion.AnswerNumberRestrictionFrom  or vQuestion.SelectedAnswerNumber > vQuestion.AnswerNumberRestrictionTo Then
						vNewMessage 			= New UserMessage;
						vNewMessage.DataPath 	= "Questions[" + i + "].SelectedAnswerNumber";
						vNewMessage.Text		= vQuestionTitle + chars.LF + NStr("en='The answer does not fall within the allowed range: '; ru='Ответ не попадает в разрешенный диапазон: '; de='Die Antwort fällt nicht in den zulässigen Bereich: '") + Format(vQuestion.AnswerNumberRestrictionFrom, "NZ=; NG=") + " - " + Format(vQuestion.AnswerNumberRestrictionTo, "NZ=; NG=");
						vNewMessage.Message();
						vSuccess = False;
						Break;
					EndIf;
					vThereAreAnswers = True;
				EndIf;
			EndIf;
			
			If vQuestion.AnswerType = Enums.AnswerTypes.List Then
				If vQuestion.AnswerListMaxVariants > 0 Then
					vCount = 0;
					For each vAnswerVariant in vQuestion.AnswerVariants Do
						If vAnswerVariant.Selected Then
							vCount = vCount + 1;
						EndIf;
					EndDo;
					
					If vCount > vQuestion.AnswerListMaxVariants Then
						vNewMessage 			= New UserMessage;
						vNewMessage.DataPath 	= "Questions[" + i + "].SelectedAnswerNumber";
						vNewMessage.Text		= vQuestionTitle + chars.LF + NStr("en = 'The maximum number of selected answer options ='; de = 'Die maximale Anzahl ausgewählter Antwortoptionen ='; ru = 'Максимальное количество выбранных вариантов ответа =  '") + vQuestion.AnswerListMaxVariants;
						vNewMessage.Message();
						vSuccess = False;
						Break;
					ElsIf vCount > 0 Then
						vThereAreAnswers = True;
					EndIf;
				EndIf;
			EndIf;
			
			If vQuestion.Mandatory Then
				If vQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
					If vQuestion.SelectedAnswerBoolean <> 0 and vQuestion.SelectedAnswerBoolean <> 1 Then
						vSuccess = False;
					Else
						vThereAreAnswers = True;
					EndIf;
				ElsIf vQuestion.AnswerType = Enums.AnswerTypes.String Then
					If IsBlankString(vQuestion.SelectedAnswerString) Then
						vSuccess = False;
					Else
						vThereAreAnswers = True;
					EndIf;
				ElsIf vQuestion.AnswerType = Enums.AnswerTypes.Number Then
					If vQuestion.SelectedAnswerNumber = 0 Then
						vSuccess = False;
					EndIf;
				ElsIf vQuestion.AnswerType = Enums.AnswerTypes.List Then
					If vQuestion.AnswerListMaxVariants = 1 Then
						If IsBlankString(vQuestion.SelectedAnswerString) Then
							vSuccess = False;
						EndIf;
					Else
						vSuccess = False;
						For each vAnswerVariant in vQuestion.AnswerVariants Do
							If vAnswerVariant.Selected Then
								vSuccess = True;
							EndIf;
						EndDo;				
					EndIf;
				EndIf;
				
				If vSuccess = False Then
					vNewMessage 			= New UserMessage;
					vNewMessage.DataPath 	= "Questions[" + i + "].SelectedAnswerNumber";
					vNewMessage.Text		= vQuestionTitle + chars.LF + NStr("en = 'This is an obligatory question!'; de = 'Dies ist eine obligatorische Frage!'; ru = 'Это обязательный вопрос!'");
					vNewMessage.Message();
					Break;
				EndIf;
			Else
				If vQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
					If Not (vQuestion.SelectedAnswerBoolean <> 0 and vQuestion.SelectedAnswerBoolean <> 1) Then
						vThereAreAnswers = True;
					EndIf;
				ElsIf vQuestion.AnswerType = Enums.AnswerTypes.String Then
					If Not IsBlankString(vQuestion.SelectedAnswerString) Then
						vThereAreAnswers = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vQuestion.LinkedFeedbackQuestion) Then
			j = j + 1;	
		EndIf;
		i = i + 1;
	EndDo;
	
	If vSuccess And vThereAreAnswers Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Thank you for your feedback!'; de = 'Danke für die Feedback!'; ru = 'Спасибо за отзыв!'"));
		CreateClientFeedback();	
	EndIf;
	
	Return vSuccess;
EndFunction // Finish_AtServer

&AtServer
Procedure CreateClientFeedback()
	vNewDoc 			= Documents.ClientFeedback.CreateDocument();
	vNewDoc.ParentDoc	= RecorderDocument;
	vNewDoc.Survey 		= Survey;
	vNewDoc.Fill(RecorderDocument);
	vNewDoc.pmFillAttributesWithDefaultValues();	
	For each vQuestion in Questions Do
		If vQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
			If NOT vQuestion.SelectedAnswerBoolean = 9999 Then 
				vNewAnswer 							= vNewDoc.Answers.Add();
				vNewAnswer.FeedbackQuestion 		= vQuestion.Question;
				vNewAnswer.LinkedFeedbackQuestion 	= vQuestion.LinkedFeedbackQuestion;
				If vQuestion.SelectedAnswerBoolean = 1 Then 
					vNewAnswer.Answer 			= True;
				Else 
					vNewAnswer.Answer 			= False;
				EndIf;
			EndIf;
		ElsIf vQuestion.AnswerType = Enums.AnswerTypes.String Then
			If NOT IsBlankString(vQuestion.SelectedAnswerString) Then
				vNewAnswer 					= vNewDoc.Answers.Add();
				vNewAnswer.FeedbackQuestion = vQuestion.Question;
				vNewAnswer.Answer 			= TrimAll(vQuestion.SelectedAnswerString);
				vNewAnswer.LinkedFeedbackQuestion 	= vQuestion.LinkedFeedbackQuestion;
			EndIf;
		ElsIf vQuestion.AnswerType = Enums.AnswerTypes.Number Then
			If vQuestion.SelectedAnswerNumber <> 0 Then
				vNewAnswer 					= vNewDoc.Answers.Add();
				vNewAnswer.FeedbackQuestion = vQuestion.Question;
				vNewAnswer.Answer 			= vQuestion.SelectedAnswerNumber;
				vNewAnswer.LinkedFeedbackQuestion 	= vQuestion.LinkedFeedbackQuestion;
			EndIf;
		ElsIf vQuestion.AnswerType = Enums.AnswerTypes.List Then
			If vQuestion.AnswerListMaxVariants = 1 Then
				If NOT IsBlankString(vQuestion.SelectedAnswerString) Then
					vNewAnswer 					= vNewDoc.Answers.Add();
					vNewAnswer.FeedbackQuestion = vQuestion.Question;
					vNewAnswer.Answer 			= TrimAll(vQuestion.SelectedAnswerString);
					vNewAnswer.LinkedFeedbackQuestion 	= vQuestion.LinkedFeedbackQuestion;
					vNewAnswer.AnswerWeight 	= vQuestion.SelectedAnswerWeight;
				EndIf;
			Else
				For each vAnswerVariant in vQuestion.AnswerVariants Do
					If vAnswerVariant.Selected Then
						vNewAnswer 					= vNewDoc.Answers.Add();
						vNewAnswer.FeedbackQuestion = vQuestion.Question;
						vNewAnswer.Answer 			= vAnswerVariant.AnswerText;
						vNewAnswer.LinkedFeedbackQuestion 	= vQuestion.LinkedFeedbackQuestion;
					EndIf;
				EndDo;
			EndIf;
		EndIf;		
	EndDo;
	vNewDoc.Write();
EndProcedure

&AtClient
Procedure SurveysSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	Survey = pSelectedRow;
	GenerateSurvey();
EndProcedure

&AtClient
Procedure ChangeSurvey(pCommand)
	ShowInputString(New NotifyDescription("AfterPasswordEnter", ThisForm),, NStr("en = 'Enter password to change the survey'; de = 'Geben Sie ein Passwort ein, um die Umfrage zu ändern'; ru = 'Введите пароль, чтобы изменить опрос'"));	
EndProcedure

&AtClient
Procedure AfterPasswordEnter(pResult, pParams) Export
	If ValueIsFilled(pResult) Then
		If pResult = Object.Password Then
			ResetSurvey();
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Incorrect password'; de = 'Falsches Passwort'; ru = 'Неверный пароль'"));
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure ResetSurvey();
	Questions.Clear();
	Items.Surveys.Visible 			= True;
	Items.Group_Survey.Visible 		= False;
	Items.Group_Recorder.Visible 	= False;
	Items.Header.Title 			= "";
	Items.Footer.Title			= "";
	While Items.Group_Questions.ChildItems.Count() > 0 Do
		Items.Delete(Items.Group_Questions.ChildItems[0]);
	EndDo;
EndProcedure

&AtClient
Procedure AnswerField_OnChange(pItem)
	vID = Right(pItem.Name, StrLen(pItem.Name) - StrFind(pItem.Name,"ID") - 1);
	If StrFind(vID, "_") > 0 Then
		vID = Left(vID, StrFind(vID, "_") - 1);
	EndIf;
	vQuestionRow 		= Questions.Get(Number(vID));
	vCurrentAnswerType 	= GetAnswerType(vQuestionRow.Question);
	If vCurrentAnswerType = "List" Then
		If vQuestionRow.AnswerListMaxVariants = 1 Then
			For each vAnswerRow in vQuestionRow.AnswerVariants Do
				If vQuestionRow.SelectedAnswerString = vAnswerRow.AnswerText Then
					vQuestionRow.SelectedAnswerWeight = vAnswerRow.AnswerWeight;	
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	For each vRow in Questions Do
		If vRow.LinkedFeedbackQuestion = vQuestionRow.Question Then
			vAnswerType = GetAnswerType(vRow.LinkedFeedbackQuestion);
			If vAnswerType = "Boolean" Then
				If vRow.AnswerForLink = vQuestionRow.SelectedAnswerBoolean Then
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, True);
				Else
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, False);
					ResetLinkedQuestionAnswers(vQuestionRow.Question);
				EndIf;
			ElsIf vAnswerType = "String" Then
				If vRow.AnswerForLink = vQuestionRow.SelectedAnswerString Then
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, True);
				Else
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, False);
					ResetLinkedQuestionAnswers(vQuestionRow.Question);
				EndIf;
			ElsIf vAnswerType = "Number" Then
				If vRow.AnswerForLink = vQuestionRow.SelectedAnswerNumber Then
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, True);
				Else
					ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, False);
					ResetLinkedQuestionAnswers(vQuestionRow.Question);
				EndIf;
			ElsIf vAnswerType = "List" Then
				If vQuestionRow.AnswerListMaxVariants = 1 Then
					If vRow.AnswerForLink = vQuestionRow.SelectedAnswerString Then
						ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, True);
					Else
						ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, False);
						ResetLinkedQuestionAnswers(vQuestionRow.Question);
					EndIf;
				Else
					For each vAnswer in vQuestionRow.AnswerVariants Do
						If vRow.AnswerForLink = vAnswer.AnswerText and vAnswer.Selected Then
							ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, True);
							Break;
						Else
							ChangeLinkedQuestionGroupVisible(vRow.AnswerID, vID, False);
							ResetLinkedQuestionAnswers(vQuestionRow.Question);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ChangeLinkedQuestionGroupVisible(pLinkID, pID, pVisible)
	vLinkedItemGroup = Items.Find("FormGroupLinkedQuestion_ID" + pID + "_Link" + pLinkID);
	vLinkedItemGroup.Visible = pVisible;
EndProcedure

&AtClient
Procedure ResetLinkedQuestionAnswers(pQuestion)
	For each vQuestion in Questions Do
		If vQuestion.LinkedFeedbackQuestion = pQuestion Then
			vQuestion.SelectedAnswerBoolean = 9999;
			vQuestion.SelectedAnswerString 	= "";
			vQuestion.SelectedAnswerNumber 	= 0;
			vQuestion.SelectedAnswerWeight 	= 0;
			For each vAnswerVariant in vQuestion.AnswerVariants Do
				vAnswerVariant.Selected = False;	
			EndDo;
		EndIf;
	EndDo;
EndProcedure

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


&AtClient
Procedure RecorderDocumentStartChoice(pItem, pChoiceData, pStandardProcessing)	
	
	pStandardProcessing = False;
	OpenForm("Document.Accommodation.ChoiceForm", New Structure("ChoiceMode", True), RecorderDocument,,,, New NotifyDescription("AfterRecorderDocumentChoice", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterRecorderDocumentChoice(pResult, pParams) Export
	
	RecorderDocument = pResult;
	
EndProcedure
