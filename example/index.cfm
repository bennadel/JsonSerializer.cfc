<cfscript>
	

	
	serializer = new lib.JsonSerializer()
		.asInteger( "age" )
		.asDate( "dateOfBirth" )
		.asString( "favoriteColor" )
		.asString( "firstName" )
		.asString( "lastName" )
		.asString( "nickName" )
	;

	// Image that these keys are all upper-case because they came out of a database.
	tricia = {
		FIRSTNAME = "Tricia",
		LASTNAME = "Smith",
		DATEOFBIRTH = "1975/01/01",
		NICKNAME = "Trish",
		FAVORITECOLOR = "333333",
		AGE = 38
	};

	writeOutput(
		"Tricia: " & 
		serializer.serialize( tricia )
	);


</cfscript>