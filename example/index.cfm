<cfscript>
	

	// Set up our serializer, setting up the key-casing and the value
	// conversion rules. 	
	serializer = new lib.JsonSerializer()
		.asInteger( "age" )
		.asAny( "createdAt" )
		.asDate( "dateOfBirth" )
		.asString( "favoriteColor" )
		.asString( "firstName" )
		.asString( "lastName" )
		.asString( "nickName" )
		.exclude( "password" )
	;

	// Imagine that these keys are all upper-case because they came 
	// out of a database (or some other source in which the keys may
	// have been entered without proper casing).
	tricia = {
		FIRSTNAME = "Tricia",
		LASTNAME = "Smith",
		DATEOFBIRTH = dateConvert( "local2utc", "1975/01/01" ),
		NICKNAME = "Trish",
		FAVORITECOLOR = "333333",
		AGE = 38,
		CREATEDAT = now(),
		PASSWORD = "I<3ColdFusion&Cookies"
	};


</cfscript>

<cfcontent type="text/html; charset=utf-8" />

<cfoutput>

	<!doctype html>
	<html>
	<head>
		<meta charset="utf-8" />

		<title>
			JsonSerializer.cfc Example
		</title>
	</head>
	<body>

		<h1>
			JsonSerializer.cfc Example
		</h1>


		<h3>
			Tricia:
		</h3>

		<p>
			<!--- Add spaces after commas to enable word-wrap. --->
			#htmlEditFormat(
				replace(
					serializer.serialize( tricia ),
					",",
					", ",
					"all"
				)
			)#
		</p>


		<h3>
			View the JavaScript Console:
		</h3>

		<script type="text/javascript">


			var tricia = JSON.parse(
				"#JsStringFormat( serializer.serialize( tricia ) )#"
			);

			// At this point, the JavaScript object contains the
			// date-of-birth as an ISO 8601 time string. Now, we can
			// overwrite the key, converting the value from a string
			// into an actual JavaScript date object.
			tricia.dateOfBirth = new Date( tricia.dateOfBirth );

			console.dir( tricia );


		</script>

	</body>
	</html>

</cfoutput>