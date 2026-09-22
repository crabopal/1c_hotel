			  
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Program version number
//
Function cmIsFirstRun() Export
	
	Return IsBlankString(Constants.ProgramVersionNumber.Get());	
	
EndFunction // cmIsFirstRun()

// --------------------------------------------------------------------------------
// 
// Returns:
//  Boolean - Checking if the version is up to date
//
Function cmIsRelevantVersion() Export 
	
	Return (TrimAll(Constants.ProgramVersionNumber.Get()) = TrimAll(Metadata.Version));	
	
EndFunction // cmIsRelevantVersion()

// --------------------------------------------------------------------------------
// 
// Returns:
//  Boolean - Update completed 
//
Function cmRunUpdate() Export   
	// Try update infobase
	vResult = DataProcessors.InfoBaseUpdate.Create().pmDoInfobaseUpdate();
	Return vResult;	
EndFunction //  cmRunUpdate()

// --------------------------------------------------------------------------------
//
Procedure cmUpdateInfobaseVersion() Export
	If TrimAll(Constants.ProgramVersionNumber.Get()) <> TrimAll(Metadata.Version) Then
		Constants.ProgramVersionNumber.Set(Metadata.Version);   
		tcProtection.StartApplication("InfoBaseUpdate");
	EndIf;
EndProcedure // cmUpdateInfobaseVersion()

// --------------------------------------------------------------------------------
// 
// Returns:
//  Boolean - True, if actual 
//
Function IsRelevantVersionWithoutAssembly() Export  
	vRelevant = True;
	vProgramVersion = TrimAll(Constants.ProgramVersionNumber.Get()); 
	vMetadataVersion = TrimAll(Metadata.Version);  
	
	If IsBlankString(vProgramVersion) Then
		vProgramVersion = "0.0.0.0";	
	EndIf; 
	If IsBlankString(vMetadataVersion) Then
		vMetadataVersion = "0.0.0.0";	
	EndIf;    
	
	If Not vProgramVersion = vMetadataVersion Then 
		vProgramVersionArr = StrSplit(vProgramVersion, ".");
		vMetadataVersionArr = StrSplit(vMetadataVersion, ".");
		
		If vProgramVersionArr.Count() <> 4 Or vMetadataVersionArr.Count() <> 4 Then
			vRelevant = False;
		EndIf;	
		
		If vRelevant Then
			For vDigit = 0 To 2 Do
				vDiff = Number(vMetadataVersionArr[vDigit]) - Number(vProgramVersionArr[vDigit]);
				If vDiff <> 0 Then
					vRelevant = False;
					Break;
				EndIf;
			EndDo;
		EndIf;	
	EndIf;	
	Return vRelevant;
EndFunction	// IsRelevantVersionWithoutAssembly()

#EndRegion
