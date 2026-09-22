
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  ValueList - Report attributes
//
Function cmGetListOfSystemReportAttributes() Export
	vList = New ValueList();
	vList.Add("Report");
	vList.Add("ReportBuilder");
	vList.Add("QueryText");
	vList.Add("ReportAppearanceTemplateType");
	vList.Add("ReportDimensionsPlacementOnRowsType");
	vList.Add("ReportDimensionsPlacementOnColumnsType");
	vList.Add("ReportTotalsPlacementOnRowsType");
	vList.Add("ReportTotalsPlacementOnColumnsType");
	vList.Add("ReportDimensionAttributesPlacementInRowsType");
	vList.Add("ReportDimensionAttributesPlacementInColumnsType");
	vList.Add("ReportAutoscaleType");
	vList.Add("ReportPageOrientation");
	vList.Add("ReportDoNotPutReportHeader");
	vList.Add("ReportDoNotPutTableHeader");
	vList.Add("ReportDoNotPutDetailRecords");
	vList.Add("ReportDoNotPutTableFooter");
	vList.Add("ReportDoNotPutOveralls");
	vList.Add("ReportDoNotPutReportFooter");
	vList.Add("ReportColumnOverrides");
	vList.Add("ReportChartType");
	vList.Add("ReportShowChartOnOpen");
	Return vList;
EndFunction // cmGetListOfSystemReportAttributes

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSessionNumber		 - Number	 - Session number
//  pSessionStartTime	 - Date		 - Session start time
// 
// Returns:
//  Structure - app params
//
Function cmGetAppRunMode(pSessionNumber, pSessionStartTime) Export
	vResult = New Structure("MobileDeviceMode, WebClientMode, ThinClientMode, ThickClientMode", False, False, False, False);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ActiveSessions.MobileDeviceMode AS MobileDeviceMode,
	|	ActiveSessions.WebClientMode AS WebClientMode,
	|	ActiveSessions.ThinClientMode AS ThinClientMode,
	|	ActiveSessions.ThickClientMode AS ThickClientMode
	|FROM
	|	InformationRegister.ActiveSessions AS ActiveSessions
	|WHERE
	|	ActiveSessions.SessionID = &qSessionID
	|	AND ActiveSessions.Period = &qSessionStartTime";
	vQry.SetParameter("qSessionID", pSessionNumber); 
	vQry.SetParameter("qSessionStartTime", pSessionStartTime);
	vSessions = vQry.Execute().Unload();
	If vSessions.Count() > 0 Then
		vResult.MobileDeviceMode = vSessions[0].MobileDeviceMode;
		vResult.WebClientMode = vSessions[0].WebClientMode;
		vResult.ThinClientMode = vSessions[0].ThinClientMode;
		vResult.ThickClientMode = vSessions[0].ThickClientMode;		
	EndIf;
	Return vResult; 
EndFunction // cmGetAppRunMode

// --------------------------------------------------------------------------------
//  Returns color for the given ref.
//  in case color not set returns color from style as default value
//
// Parameters:
//  pRef			 - AnyRef	 - Ref
//  pStyleColorName	 - String	 - Color name
// 
// Returns:
//  Color - Color
//
Function cmGetColorByColorStringFromRef(pRef, pStyleColorName = "") Export
	
	If ValueIsFilled(pRef) And Not pRef.IsFolder And Not IsBlankString(pRef.ColorString) Then
		Try
			Return XDTOSerializer.XMLValue(Type("Color"), TrimAll(pRef.ColorString));
		Except
		EndTry;
	EndIf;    
	
	If ValueIsFilled(pStyleColorName) Then
		Try
			Return StyleColors[pStyleColorName];	
		Except
		EndTry;
	EndIf;
	
	Return tcCommonFunctionOnClientServer.ColorConstructor();
EndFunction // cmGetColorByColorStringFromRef

// --------------------------------------------------------------------------------
//  Returns color for the given ref.
//  in case color not set returns color from style as default value
//
// Parameters:
//  pRef			 - AnyRef	 - Ref
//  pStyleColorName	 - String	 - Color name
// 
// Returns:
//  Color - Color
//
Function cmGetColorByColorValueStorageFromRef(pRef, pStyleColorName = "") Export
	
	If ValueIsFilled(pRef) Then
		Try  
			vColor = pRef.Color.Get();
			If vColor <> Undefined Then 
				Return vColor;
			EndIf;
		Except
		EndTry;
	EndIf;    
	
	If ValueIsFilled(pStyleColorName) Then
		Try
			Return StyleColors[pStyleColorName];
		Except
		EndTry;
	EndIf;
	
	Return tcCommonFunctionOnClientServer.ColorConstructor();
EndFunction // cmGetColorByColorValueStorageFromRef

// --------------------------------------------------------------------------------
//  Get a web color table with absolute colors.
// 
// Returns:
//  Map - Color map
//
Function WebColorCatalog() Export
	
	vColorMap = New Map;
    	
	vColorMap.Insert(WebColors.Aquamarine,					tcCommonFunctionOnClientServer.ColorConstructor(127, 255, 212));
	vColorMap.Insert(WebColors.AliceBlue,					tcCommonFunctionOnClientServer.ColorConstructor(240, 248, 255));
	vColorMap.Insert(WebColors.AntiqueWhite,				tcCommonFunctionOnClientServer.ColorConstructor(250, 235, 215));
	vColorMap.Insert(WebColors.Beige,						tcCommonFunctionOnClientServer.ColorConstructor(245, 245, 220));
	vColorMap.Insert(WebColors.Snow,						tcCommonFunctionOnClientServer.ColorConstructor(255, 250, 250));
	vColorMap.Insert(WebColors.White,						tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255));
	vColorMap.Insert(WebColors.Turquoise,					tcCommonFunctionOnClientServer.ColorConstructor(064, 224, 208));
	vColorMap.Insert(WebColors.PaleTurquoise,				tcCommonFunctionOnClientServer.ColorConstructor(175, 238, 238));
	vColorMap.Insert(WebColors.PaleGreen,					tcCommonFunctionOnClientServer.ColorConstructor(152, 251, 152));
	vColorMap.Insert(WebColors.PaleGoldenrod,				tcCommonFunctionOnClientServer.ColorConstructor(238, 232, 170));
	vColorMap.Insert(WebColors.PaleVioletRed,				tcCommonFunctionOnClientServer.ColorConstructor(219, 112, 147));
	vColorMap.Insert(WebColors.Lavender,					tcCommonFunctionOnClientServer.ColorConstructor(230, 230, 250));
	vColorMap.Insert(WebColors.BlanchedAlmond,				tcCommonFunctionOnClientServer.ColorConstructor(255, 235, 205));
	vColorMap.Insert(WebColors.Thistle,						tcCommonFunctionOnClientServer.ColorConstructor(216, 191, 216));
	vColorMap.Insert(WebColors.CornFlowerBlue,				tcCommonFunctionOnClientServer.ColorConstructor(100, 149, 237));
	vColorMap.Insert(WebColors.SpringGreen,					tcCommonFunctionOnClientServer.ColorConstructor(000, 255, 127));
	vColorMap.Insert(WebColors.LightBlue,					tcCommonFunctionOnClientServer.ColorConstructor(166, 202, 240));
	vColorMap.Insert(WebColors.LavenderBlush,				tcCommonFunctionOnClientServer.ColorConstructor(255, 240, 245));
	vColorMap.Insert(WebColors.LightSteelBlue,				tcCommonFunctionOnClientServer.ColorConstructor(176, 196, 222));
	vColorMap.Insert(WebColors.SlateGray,					tcCommonFunctionOnClientServer.ColorConstructor(112, 128, 144));
	vColorMap.Insert(WebColors.SlateBlue,					tcCommonFunctionOnClientServer.ColorConstructor(106, 090, 205));
	vColorMap.Insert(WebColors.BurlyWood,					tcCommonFunctionOnClientServer.ColorConstructor(222, 184, 135));
	vColorMap.Insert(WebColors.WhiteSmoke,					tcCommonFunctionOnClientServer.ColorConstructor(245, 245, 245));
	vColorMap.Insert(WebColors.YellowGreen,					tcCommonFunctionOnClientServer.ColorConstructor(154, 205, 050));
	vColorMap.Insert(WebColors.Yellow,						tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 000));
	vColorMap.Insert(WebColors.Moccasin,					tcCommonFunctionOnClientServer.ColorConstructor(255, 228, 181));
	vColorMap.Insert(WebColors.LawnGreen,					tcCommonFunctionOnClientServer.ColorConstructor(124, 252, 000));
	vColorMap.Insert(WebColors.GreenYellow,					tcCommonFunctionOnClientServer.ColorConstructor(173, 255, 047));
	vColorMap.Insert(WebColors.Chartreuse,					tcCommonFunctionOnClientServer.ColorConstructor(127, 255, 000));
	vColorMap.Insert(WebColors.Lime,						tcCommonFunctionOnClientServer.ColorConstructor(000, 255, 000));
	vColorMap.Insert(WebColors.Green,						tcCommonFunctionOnClientServer.ColorConstructor(000, 128, 000));
	vColorMap.Insert(WebColors.ForestGreen,					tcCommonFunctionOnClientServer.ColorConstructor(034, 139, 034));
	vColorMap.Insert(WebColors.Goldenrod,					tcCommonFunctionOnClientServer.ColorConstructor(218, 165, 032));
	vColorMap.Insert(WebColors.Gold,						tcCommonFunctionOnClientServer.ColorConstructor(255, 215, 000));
	vColorMap.Insert(WebColors.Indigo,						tcCommonFunctionOnClientServer.ColorConstructor(075, 000, 130));
	vColorMap.Insert(WebColors.IndianRed,					tcCommonFunctionOnClientServer.ColorConstructor(205, 092, 092));
	vColorMap.Insert(WebColors.FireBrick,					tcCommonFunctionOnClientServer.ColorConstructor(178, 034, 034));
	vColorMap.Insert(WebColors.SaddleBrown,					tcCommonFunctionOnClientServer.ColorConstructor(139, 069, 019));
	vColorMap.Insert(WebColors.Coral,						tcCommonFunctionOnClientServer.ColorConstructor(255, 127, 080));
	vColorMap.Insert(WebColors.Brown,						tcCommonFunctionOnClientServer.ColorConstructor(165, 042, 042));
	vColorMap.Insert(WebColors.RoyalBlue,					tcCommonFunctionOnClientServer.ColorConstructor(065, 105, 225));
	vColorMap.Insert(WebColors.VioletRed,					tcCommonFunctionOnClientServer.ColorConstructor(208, 032, 144));
	vColorMap.Insert(WebColors.Red,							tcCommonFunctionOnClientServer.ColorConstructor(255, 000, 000));
	vColorMap.Insert(WebColors.Cream,						tcCommonFunctionOnClientServer.ColorConstructor(255, 251, 240));
	vColorMap.Insert(WebColors.Azure,						tcCommonFunctionOnClientServer.ColorConstructor(240, 255, 255));
	vColorMap.Insert(WebColors.LimeGreen,					tcCommonFunctionOnClientServer.ColorConstructor(050, 205, 050));
	vColorMap.Insert(WebColors.LemonChiffon,				tcCommonFunctionOnClientServer.ColorConstructor(255, 250, 205));
	vColorMap.Insert(WebColors.Salmon,						tcCommonFunctionOnClientServer.ColorConstructor(250, 128, 114));
	vColorMap.Insert(WebColors.LightSalmon,					tcCommonFunctionOnClientServer.ColorConstructor(255, 160, 122));
	vColorMap.Insert(WebColors.DarkSalmon,					tcCommonFunctionOnClientServer.ColorConstructor(233, 150, 122));
	vColorMap.Insert(WebColors.Льняной,						tcCommonFunctionOnClientServer.ColorConstructor(250, 240, 230));
	vColorMap.Insert(WebColors.Малиновый,					tcCommonFunctionOnClientServer.ColorConstructor(220, 020, 060));
	vColorMap.Insert(WebColors.МятныйКрем,					tcCommonFunctionOnClientServer.ColorConstructor(245, 255, 250));
	vColorMap.Insert(WebColors.НавахоБелый,					tcCommonFunctionOnClientServer.ColorConstructor(255, 222, 173));
	vColorMap.Insert(WebColors.НасыщенноНебесноГолубой,		tcCommonFunctionOnClientServer.ColorConstructor(000, 191, 255));
	vColorMap.Insert(WebColors.НасыщенноРозовый,			tcCommonFunctionOnClientServer.ColorConstructor(255, 020, 147));
	vColorMap.Insert(WebColors.НебесноГолубой,				tcCommonFunctionOnClientServer.ColorConstructor(135, 206, 235));
	vColorMap.Insert(WebColors.НейтральноАквамариновый,		tcCommonFunctionOnClientServer.ColorConstructor(102, 205, 170));
	vColorMap.Insert(WebColors.НейтральноБирюзовый,			tcCommonFunctionOnClientServer.ColorConstructor(072, 209, 204));
	vColorMap.Insert(WebColors.НейтральноВесеннеЗеленый,	tcCommonFunctionOnClientServer.ColorConstructor(000, 250, 154));
	vColorMap.Insert(WebColors.НейтральноГрифельноСиний,	tcCommonFunctionOnClientServer.ColorConstructor(123, 104, 238));
	vColorMap.Insert(WebColors.НейтральноЗеленый,			tcCommonFunctionOnClientServer.ColorConstructor(192, 220, 192));
	vColorMap.Insert(WebColors.НейтральноКоричневый,		tcCommonFunctionOnClientServer.ColorConstructor(205, 133, 63));
	vColorMap.Insert(WebColors.НейтральноПурпурный,			tcCommonFunctionOnClientServer.ColorConstructor(147, 112, 219));
	vColorMap.Insert(WebColors.НейтральноСерый,				tcCommonFunctionOnClientServer.ColorConstructor(160, 160, 164));
	vColorMap.Insert(WebColors.НейтральноСиний,				tcCommonFunctionOnClientServer.ColorConstructor(000, 000, 205));
	vColorMap.Insert(WebColors.НейтральноФиолетовоКрасный,	tcCommonFunctionOnClientServer.ColorConstructor(199, 021, 133));
	vColorMap.Insert(WebColors.Оливковый,					tcCommonFunctionOnClientServer.ColorConstructor(128, 128, 000));
	vColorMap.Insert(WebColors.ОранжевоКрасный,				tcCommonFunctionOnClientServer.ColorConstructor(255, 069, 000));
	vColorMap.Insert(WebColors.Оранжевый,					tcCommonFunctionOnClientServer.ColorConstructor(255, 165, 000));
	vColorMap.Insert(WebColors.Орхидея,						tcCommonFunctionOnClientServer.ColorConstructor(218, 112, 214));
	vColorMap.Insert(WebColors.ОрхидеяНейтральный,			tcCommonFunctionOnClientServer.ColorConstructor(186, 085, 211));
	vColorMap.Insert(WebColors.ОрхидеяТемный,				tcCommonFunctionOnClientServer.ColorConstructor(153, 050, 204));
	vColorMap.Insert(WebColors.Охра,						tcCommonFunctionOnClientServer.ColorConstructor(160, 082, 045));
	vColorMap.Insert(WebColors.Перламутровый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 245, 238));
	vColorMap.Insert(WebColors.Персиковый,					tcCommonFunctionOnClientServer.ColorConstructor(255, 218, 185));
	vColorMap.Insert(WebColors.ПесочноКоричневый,			tcCommonFunctionOnClientServer.ColorConstructor(244, 164, 096));
	vColorMap.Insert(WebColors.ПолночноСиний,				tcCommonFunctionOnClientServer.ColorConstructor(025, 025, 112));
	vColorMap.Insert(WebColors.ПризрачноБелый,				tcCommonFunctionOnClientServer.ColorConstructor(248, 248, 255));
	vColorMap.Insert(WebColors.Пурпурный,					tcCommonFunctionOnClientServer.ColorConstructor(128, 000, 128));
	vColorMap.Insert(WebColors.Пшеничный,					tcCommonFunctionOnClientServer.ColorConstructor(245, 222, 179));
	vColorMap.Insert(WebColors.РозовоКоричневый,			tcCommonFunctionOnClientServer.ColorConstructor(188, 143, 143));
	vColorMap.Insert(WebColors.Розовый,						tcCommonFunctionOnClientServer.ColorConstructor(255, 192, 203));
	vColorMap.Insert(WebColors.Роса,						tcCommonFunctionOnClientServer.ColorConstructor(240, 255, 240));
	vColorMap.Insert(WebColors.РыжеватоКоричневый,			tcCommonFunctionOnClientServer.ColorConstructor(210, 180, 140));
	vColorMap.Insert(WebColors.СветлоГрифельноСерый,		tcCommonFunctionOnClientServer.ColorConstructor(119, 136, 153));
	vColorMap.Insert(WebColors.СветлоГрифельноСиний,		tcCommonFunctionOnClientServer.ColorConstructor(132, 112, 255));
	vColorMap.Insert(WebColors.СветлоЖелтый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 224));
	vColorMap.Insert(WebColors.СветлоЖелтыйЗолотистый,		tcCommonFunctionOnClientServer.ColorConstructor(250, 250, 210));
	vColorMap.Insert(WebColors.СветлоЗеленый,				tcCommonFunctionOnClientServer.ColorConstructor(144, 238, 144));
	vColorMap.Insert(WebColors.СветлоЗолотистый,			tcCommonFunctionOnClientServer.ColorConstructor(255, 236, 139));
	vColorMap.Insert(WebColors.СветлоКоралловый,			tcCommonFunctionOnClientServer.ColorConstructor(240, 128, 128));
	vColorMap.Insert(WebColors.СветлоКоричневый,			tcCommonFunctionOnClientServer.ColorConstructor(255, 228, 196));
	vColorMap.Insert(WebColors.СветлоНебесноГолубой,		tcCommonFunctionOnClientServer.ColorConstructor(135, 206, 250));
	vColorMap.Insert(WebColors.СветлоРозовый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 182, 193));
	vColorMap.Insert(WebColors.СветлоСерый,					tcCommonFunctionOnClientServer.ColorConstructor(192, 192, 192));
	vColorMap.Insert(WebColors.СеребристоСерый,				tcCommonFunctionOnClientServer.ColorConstructor(220, 220, 220));
	vColorMap.Insert(WebColors.Серебряный,					tcCommonFunctionOnClientServer.ColorConstructor(192, 192, 192));
	vColorMap.Insert(WebColors.СероСиний,					tcCommonFunctionOnClientServer.ColorConstructor(095, 158, 160));
	vColorMap.Insert(WebColors.Серый,						tcCommonFunctionOnClientServer.ColorConstructor(128, 128, 128));
	vColorMap.Insert(WebColors.СинеСерый,					tcCommonFunctionOnClientServer.ColorConstructor(030, 144, 255));
	vColorMap.Insert(WebColors.СинеФиолетовый,				tcCommonFunctionOnClientServer.ColorConstructor(138, 043, 226));
	vColorMap.Insert(WebColors.Синий,						tcCommonFunctionOnClientServer.ColorConstructor(000, 000, 255));
	vColorMap.Insert(WebColors.СинийСПороховымОттенком,		tcCommonFunctionOnClientServer.ColorConstructor(176, 224, 230));
	vColorMap.Insert(WebColors.СинийСоСтальнымОттенком,		tcCommonFunctionOnClientServer.ColorConstructor(070, 130, 180));
	vColorMap.Insert(WebColors.Сливовый,					tcCommonFunctionOnClientServer.ColorConstructor(221, 160, 221));
	vColorMap.Insert(WebColors.СлоноваяКость,				tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 240));
	vColorMap.Insert(WebColors.СтароеКружево,				tcCommonFunctionOnClientServer.ColorConstructor(253, 245, 230));
	vColorMap.Insert(WebColors.ТемноБирюзовый,				tcCommonFunctionOnClientServer.ColorConstructor(000, 206, 209));
	vColorMap.Insert(WebColors.ТемноБордовый,				tcCommonFunctionOnClientServer.ColorConstructor(128, 000, 000));
	vColorMap.Insert(WebColors.ТемноГрифельноСерый,			tcCommonFunctionOnClientServer.ColorConstructor(047, 079, 079));
	vColorMap.Insert(WebColors.ТемноГрифельноСиний,			tcCommonFunctionOnClientServer.ColorConstructor(072, 061, 139));
	vColorMap.Insert(WebColors.ТемноЗеленый,				tcCommonFunctionOnClientServer.ColorConstructor(000, 100, 000));
	vColorMap.Insert(WebColors.ТемноЗолотистый,				tcCommonFunctionOnClientServer.ColorConstructor(184, 134, 011));
	vColorMap.Insert(WebColors.ТемноКрасный,				tcCommonFunctionOnClientServer.ColorConstructor(139, 000, 000));
	vColorMap.Insert(WebColors.ТемноОливковоЗеленый,		tcCommonFunctionOnClientServer.ColorConstructor(085, 107, 47));
	vColorMap.Insert(WebColors.ТемноОранжевый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 140, 000));
	vColorMap.Insert(WebColors.ТемноСерый,					tcCommonFunctionOnClientServer.ColorConstructor(169, 169, 169));
	vColorMap.Insert(WebColors.ТемноСиний,					tcCommonFunctionOnClientServer.ColorConstructor(000, 000, 139));
	vColorMap.Insert(WebColors.ТемноФиолетовый,				tcCommonFunctionOnClientServer.ColorConstructor(148, 000, 211));
	vColorMap.Insert(WebColors.ТеплоРозовый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 105, 180));
	vColorMap.Insert(WebColors.Томатный,					tcCommonFunctionOnClientServer.ColorConstructor(255, 099, 071));
	vColorMap.Insert(WebColors.ТопленоеМолоко,				tcCommonFunctionOnClientServer.ColorConstructor(255, 239, 213));
	vColorMap.Insert(WebColors.ТусклоОливковый,				tcCommonFunctionOnClientServer.ColorConstructor(107, 142, 035));
	vColorMap.Insert(WebColors.ТусклоРозовый,				tcCommonFunctionOnClientServer.ColorConstructor(255, 228, 225));
	vColorMap.Insert(WebColors.ТусклоСерый,					tcCommonFunctionOnClientServer.ColorConstructor(105, 105, 105));
	vColorMap.Insert(WebColors.Ультрамарин,					tcCommonFunctionOnClientServer.ColorConstructor(000, 000, 128));
	vColorMap.Insert(WebColors.Фиолетовый,					tcCommonFunctionOnClientServer.ColorConstructor(238, 130, 238));
	vColorMap.Insert(WebColors.Фуксин,						tcCommonFunctionOnClientServer.ColorConstructor(255, 000, 255));
	vColorMap.Insert(WebColors.ФуксинТемный,				tcCommonFunctionOnClientServer.ColorConstructor(139, 000, 139));
	vColorMap.Insert(WebColors.Фуксия,						tcCommonFunctionOnClientServer.ColorConstructor(255, 000, 255));
	vColorMap.Insert(WebColors.Хаки,						tcCommonFunctionOnClientServer.ColorConstructor(240, 230, 140));
	vColorMap.Insert(WebColors.ХакиТемный,					tcCommonFunctionOnClientServer.ColorConstructor(189, 183, 107));
	vColorMap.Insert(WebColors.ЦветМорскойВолны,			tcCommonFunctionOnClientServer.ColorConstructor(046, 139, 087));
	vColorMap.Insert(WebColors.ЦветМорскойВолныНейтральный,	tcCommonFunctionOnClientServer.ColorConstructor(060, 179, 113));
	vColorMap.Insert(WebColors.ЦветМорскойВолныСветлый,		tcCommonFunctionOnClientServer.ColorConstructor(032, 178, 170));
	vColorMap.Insert(WebColors.ЦветМорскойВолныТемный,		tcCommonFunctionOnClientServer.ColorConstructor(143, 188, 139));
	vColorMap.Insert(WebColors.ЦветокБелый,					tcCommonFunctionOnClientServer.ColorConstructor(255, 250, 240));
	vColorMap.Insert(WebColors.Циан,						tcCommonFunctionOnClientServer.ColorConstructor(000, 255, 255));
	vColorMap.Insert(WebColors.ЦианАкварельный,				tcCommonFunctionOnClientServer.ColorConstructor(000, 255, 255));
	vColorMap.Insert(WebColors.ЦианНейтральный,				tcCommonFunctionOnClientServer.ColorConstructor(000, 128, 128));
	vColorMap.Insert(WebColors.ЦианСветлый,					tcCommonFunctionOnClientServer.ColorConstructor(224, 255, 255));
	vColorMap.Insert(WebColors.ЦианТемный,					tcCommonFunctionOnClientServer.ColorConstructor(000, 139, 139));
	vColorMap.Insert(WebColors.Черный,						tcCommonFunctionOnClientServer.ColorConstructor(000, 000, 000));
	vColorMap.Insert(WebColors.ШелковыйОттенок,				tcCommonFunctionOnClientServer.ColorConstructor(255, 248, 220));
	vColorMap.Insert(WebColors.Шоколадный,					tcCommonFunctionOnClientServer.ColorConstructor(210, 105, 30));
	
	Return vColorMap;
	
EndFunction

// -----------------------------------------------------------------------------
//  Description: Checks if current user has role specified as parameter
//
// Parameters:
//  pRoleName	 - String	 - User role description
// 
// Returns:
//  Boolean - Role Availability
//
Function cmIsInRole(pRoleName) Export   
	Return IsInRole(pRoleName);
EndFunction // cmIsInRole

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel			 - CatalogRef.Hotels - Hotel
//  pThisNode		 - ExchangePlanRef	 - The this node
//  pIsUnloadArray	 - Boolean			 - Unload to array
// 
// Returns:
//  QueryResultSelection - Exchange plan nodes list
//
Function cmGetExchangePlanNodesForCentralOfficeExchangePlan(pHotel = Undefined, pThisNode = Undefined) Export 
	vQry = New Query();	
	vQry.Text = 
	"SELECT
	|	ExchangePlanNodes.Ref AS Ref
	|FROM
	|	ExchangePlan.CentralOfficeExchangePlan AS ExchangePlanNodes
	|WHERE
	|	NOT ExchangePlanNodes.DeletionMark
	|	AND ExchangePlanNodes.OnlineSyncIsActive
	|	AND (ExchangePlanNodes.Hotel = &qHotel
	|			OR ExchangePlanNodes.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND ExchangePlanNodes.Ref <> &qThisNode
	|
	|ORDER BY
	|	ExchangePlanNodes.Code";  
	If ValueIsFilled(pHotel) Then 
		vQry.SetParameter("qHotel", pHotel);
	Else
		vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());	
	EndIf;
	If ValueIsFilled(pThisNode) Then 
		vQry.SetParameter("qThisNode", pThisNode);
	Else
		vQry.SetParameter("qThisNode", ExchangePlans.CentralOfficeExchangePlan.EmptyRef());	
	EndIf;
	
	vResult = vQry.Execute().Unload(); 
	
	Return vResult.UnloadColumn("Ref"); 
EndFunction // cmGetExchangePlanNodesForCentralOfficeExchangePlan

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel			 - CatalogRef.Hotels - Hotel
//  pThisNode		 - ExchangePlanRef	 - The this node
//  pIsUnloadArray	 - Boolean			 - Unload to array
// 
// Returns:
//  QueryResultSelection - Exchange plan nodes list
//
Function cmGetExchangePlanNodesForReplicationExchangePlan(pHotel = Undefined, pThisNode = Undefined) Export 
	vQry = New Query();	
	vQry.Text = 
	"SELECT
	|	ExchangePlanNodes.Ref AS Ref,
	|	ExchangePlanNodes.Code AS Code
	|FROM
	|	ExchangePlan.ReplicationExchangePlan AS ExchangePlanNodes
	|WHERE
	|	NOT ExchangePlanNodes.DeletionMark
	|	AND ExchangePlanNodes.OnlineSyncIsActive
	|	AND ExchangePlanNodes.Ref <> &qThisNode
	|
	|ORDER BY
	|	ExchangePlanNodes.Code";
	If ValueIsFilled(pThisNode) Then 
		vQry.SetParameter("qThisNode", pThisNode);
	Else
		vQry.SetParameter("qThisNode", ExchangePlans.CentralOfficeExchangePlan.EmptyRef());	
	EndIf;

	vResult = vQry.Execute().Unload(); 
	
	Return vResult.UnloadColumn("Ref"); 
EndFunction // cmGetExchangePlanNodesForReplicationExchangePlan

// -----------------------------------------------------------------------------
Function cmForceAPIExchangeInASCII() Export
	Return Constants.ForceAPIExchangeInASCII.Get();
EndFunction // cmForceAPIExchangeInASCII

// -----------------------------------------------------------------------------
Function cmGetSalutationBySex(pSex) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Salutations.Ref AS Ref
	|FROM
	|	Catalog.Salutations AS Salutations
	|WHERE
	|	Salutations.Sex = &qSex
	|	AND NOT Salutations.DeletionMark
	|
	|ORDER BY
	|	Salutations.Code";
	vQry.SetParameter("qSex", pSex);
	vRefs = vQry.Execute().Unload();
	If vRefs.Count() = 1 Then
		Return vRefs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetSalutationBySex

// -----------------------------------------------------------------------------
Function cmGetContentAIProjectId() Export
	Return Constants.ContentAIProjectId.Get();
EndFunction // cmGetContentAIProjectId

#EndRegion

