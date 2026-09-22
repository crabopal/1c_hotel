
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.JSONDataExporter.Form.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		ExportData();	
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure ExportData() Export
	
	vTimeStamp = "";
	
	If UseTimeStampInFileNames Then
		vTimeStamp = Format(CurrentSessionDate(),"DF='yyyy-MM-dd HH-mm-ss'");
	EndIf;
	
	vJSON 		= GetRoomTypesJSON();
	vFileName	= "\roomtypes" + vTimeStamp + ".JSON";
	SaveAndSendJSON(vJSON, vFileName, "Room types JSON export");

	vJSON 		= GetInHouseJSON();
	vFileName	= "\inhouse" + vTimeStamp + ".JSON";
	SaveAndSendJSON(vJSON, vFileName, "Inhouse JSON export");

	vJSON 		= GetCompaniesJSON();
	vFileName	= "\companies" + vTimeStamp + ".JSON";
	SaveAndSendJSON(vJSON, vFileName, "Companies JSON export");

	vJSON 		= GetBoardBasisJSON();
	vFileName	= "\boardbasis" + vTimeStamp + ".JSON";
	SaveAndSendJSON(vJSON, vFileName, "Board basis JSON export");

	vJSON 		= GetAccompanyGuestJSON();
	vFileName	= "\accompanyguest" + vTimeStamp + ".JSON";
	SaveAndSendJSON(vJSON, vFileName, "Accompany guest JSON export");

EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SaveAndSendJSON(pJSON, pFileName, pEmailDescription)
	
	vFileName 			= pFileName;
	If ValueIsFilled(ExportFolder) Then
		vFullFileName	= ExportFolder + pFileName; 
	Else
		vFullFileName	= GetTempFileName(".JSON");
	EndIf;
	
	vTextWriter = New TextWriter(vFullFileName);
	vTextWriter.Write(pJSON);
	vTextWriter.Close();

	If Not ValueIsFilled(ExportFolder) Then
		vFile 			= New File(vFullFileName);
		vFileName 		= vFile.Name;
	EndIf;
	
	If ValueIsFilled(ExportEmail) Then 
		vFilesMap = New Map;
		vFilesMap.Insert(vFileName, vFullFileName);
		JobsScheduled.cmSendFilesByEMail(pEmailDescription, "", ExportEmail, vFilesMap);   
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
Function GetRoomTypesJSON()
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomTypes.Code AS ROOMTYPE,
		|	RoomTypes.Description AS ROOMDESCRIPTION
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder";
	
	vQueryResult = vQuery.Execute().Unload();

	vJSON = Catalogs.DataConvertationRules.MapToJSON(vQueryResult);
	
	Return vJSON;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetInHouseJSON()
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Accommodation.Guest.FirstName AS FIRSTNAME,
		|	Accommodation.Guest.LastName AS LASTNAME,
		|	Accommodation.RoomType.Code AS BEDTYPE,
		|	Accommodation.ServicePackage.Code AS BOARDBASIS,
		|	Accommodation.Customer.Code AS Company,
		|	Accommodation.Customer.LegacyName AS COMPANYNAME,
		|	Accommodation.GuestGroup.Code AS CONFNUM,
		|	Accommodation.Guest.Code AS PROFILENUM,
		|	Accommodation.Room.Description AS ROOMNUMBER,
		|	Accommodation.NumberOfAdults AS ADULTS,
		|	Accommodation.NumberOfTeenagers + Accommodation.NumberOfChildren + Accommodation.NumberOfInfants AS CHILD,
		|	Accommodation.CheckInDate AS CHECKIN,
		|	Accommodation.CheckOutDate AS CHECKOUT,
		|	""I"" AS FOLIOSTATUS,
		|	Accommodation.NumberOfInfants AS INFANT,
		|	Accommodation.Guest.EMail AS EMAIL,
		|	Accommodation.Guest.Citizenship.Description AS Country
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.AccommodationTemplate <> &qEmptyAccTemplate
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND Accommodation.AccommodationStatus.IsActive";
	
	vQuery.SetParameter("qEmptyAccTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	
	vQueryResult = vQuery.Execute().Unload();

	vJSON = Catalogs.DataConvertationRules.MapToJSON(vQueryResult);
	
	Return vJSON;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetCompaniesJSON()
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Customers.Code AS ACCOUNT,
		|	Customers.LegacyName AS NAME,
		|	Customers.Country.Description AS COUNTRY
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	NOT Customers.DeletionMark
		|	AND NOT Customers.IsFolder";
	
	vQueryResult = vQuery.Execute().Unload();

	vJSON = Catalogs.DataConvertationRules.MapToJSON(vQueryResult);
	
	Return vJSON;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetBoardBasisJSON()
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ServicePackages.Code AS USERFIELD,
		|	ServicePackages.Description AS DESCRIPTION
		|FROM
		|	Catalog.ServicePackages AS ServicePackages
		|WHERE
		|	NOT ServicePackages.DeletionMark
		|	AND NOT ServicePackages.IsFolder
		|	AND ServicePackages.IsMealBoardTerm";
	
	vQueryResult = vQuery.Execute().Unload();

	vJSON = Catalogs.DataConvertationRules.MapToJSON(vQueryResult);
	
	Return vJSON;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetAccompanyGuestJSON()
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Accommodation.GuestGroup.Code AS YRPL_YRES_ID,
		|	Accommodation.Guest.Code AS YRPL_XCMS_ID,
		|	Accommodation.Guest.DateOfBirth AS XCID_BIRTHTIME
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.AccommodationTemplate = &qEmptyAccTemplate
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND Accommodation.AccommodationStatus.IsActive";
	
	vQuery.SetParameter("qEmptyAccTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	vQueryResult = vQuery.Execute().Unload();


	vJSON = Catalogs.DataConvertationRules.MapToJSON(vQueryResult);
	
	Return vJSON;
	
EndFunction

#EndRegion
