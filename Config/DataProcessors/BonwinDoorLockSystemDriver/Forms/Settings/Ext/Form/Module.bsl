
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("IP", IP);
	vParams.Insert("Port", Port);
	vParams.Insert("DataBaseType", DataBaseType);
	vParams.Insert("DataSource", DataSource);
	vParams.Insert("Password", Password);
	vParams.Insert("UserID", UserID);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.Write();
EndProcedure

&AtClient
Procedure CommandSaveAndClose(Command)
	CommandSaveAtServer();
	ThisForm.Close();
EndProcedure

&AtClient
Procedure CommandClose(Command)
	ThisForm.Close();
EndProcedure

&AtClient
Procedure CommandSave(Command)
	CommandSaveAtServer();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Try
	DoorLockSystemParameters = ThisForm.Parameters.DoorLockSystemParameters;
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	vParams = objDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
	vParams.Property("IP", IP);
	vParams.Property("Port", Port);
	vParams.Property("DataBaseType", DataBaseType);
	vParams.Property("DataSource", DataSource);
	vParams.Property("Password", Password);
	vParams.Property("UserID", UserID);
	Except
	EndTry;
EndProcedure
