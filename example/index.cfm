<cfscript>
	

	// Set up our serializer, setting up the key-casing and the value conversions. 	
	serializer = new lib.JsonSerializer()
		.asInteger( "age" )
		.asAny( "createdAt" )
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
		AGE = 38,
		CREATEDAT = now()
	};

	writeOutput(
		"Tricia: " & 
		serializer.serialize( tricia )
	);


</cfscript>