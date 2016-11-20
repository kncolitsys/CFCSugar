<cfcomponent output="false">

<cfset variables.endpoint = "">
<cfset variables.username = "">
<cfset variables.password = "">
<cfset variables.sessionid = "">

<cffunction name="init" access="public" returnType="any" output="false" hint="Initialize your CRM. Allow for auto login as well.">
	<cfargument name="endpoint" type="string" required="true" hint="The WSDL location for your CRM implementation.">
	<cfargument name="username" type="string" required="true" hint="Your username.">
	<cfargument name="password" type="string" required="true" hint="Your password. NOT hashed.">
	<cfargument name="autologin" type="boolean" required="false" default="false">
	
	<cfset variables.endpoint = arguments.endpoint>
	<cfset variables.username = arguments.username>
	<cfset variables.password = arguments.password>
	
	<cfif arguments.autologin>
		<cfset login()>
	</cfif>
	
	<cfreturn this>
</cffunction>

<cffunction name="entryListToQuery" access="private" returnType="query" output="false" hint="Converts SugarCRM Entry List to Query">
	<cfargument name="entrylist" type="any" required="true" hint="Entry_List_Result Java object">
	<!--- get the real list --->
	<cfset var list = arguments.entrylist.getEntry_list()>
	<cfset var fieldList = arguments.entrylist.getField_list()>
	<cfset var fields = "">
	<cfset var fieldsdata = "">
	
	<cfset var q = "">
	<cfset var entry = "">
	<cfset var f = "">
	<cfset var values = "">
	<cfset var fieldListElement = "">
		
	<!--- generate fields --->
	<cfloop index = "fieldListElement" from="1" to="#arrayLen(fieldList)#">
		<cfset f = fieldList[fieldListElement]>
		<cfset fields = listAppend(fields, f.getName())>
		<cfif f.getType() is "int">
			<cfset fieldsdata = listAppend(fieldsdata,"Integer")>
		<cfelseif f.getType() is "date">
			<cfset fieldsdata = listAppend(fieldsdata,"Date")>
		<cfelseif f.getType() is "bool">
			<cfset fieldsdata = listAppend(fieldsdata,"Bit")>
		<cfelse>
			<cfset fieldsdata = listAppend(fieldsdata,"VarChar")>
		</cfif>
	</cfloop>
	
	<cfset q = queryNew(fields,fieldsdata)>
	<cfloop index="entry" array="#list#">
		<cfset queryAddRow(q)>
		<cfset values = entry.getName_value_list()>
		<cfloop index="fieldListElement" from="1" to="#arrayLen(values)#">
			<cfset f = values[fieldListElement]>
			<cfset q[f.getName()][q.recordCount] = f.getValue()>
		</cfloop>
	</cfloop>

	<cfreturn q>
</cffunction>

<cffunction name="get" access="public" returnType="struct" output="false" hint="Returns an object">
	<cfargument name="type" type="string" required="true" hint="What data to get: Opportunities, Contacts, etc.">
	<cfargument name="id" type="string" required="true" hint="What id to retrieve.">
	<cfargument name="fields" type="string" required="false" default="" hint="A list of fields you want returned. SugarCRM will perform better if you filter the results.">
	<cfset var result = "">
	
	<cfinvoke webservice="#variables.endpoint#" method="get_entry" returnVariable="result" session="#variables.sessionid#">
		<cfinvokeargument name="module_name" value="#arguments.type#">
		<cfinvokeargument name="id" value="#arguments.id#">
		<cfinvokeargument name="select_fields" value="#listToArray(arguments.fields)#">
	</cfinvoke>

	<cfreturn queryToStruct(entryListToQuery(result))>
</cffunction>

<cffunction name="getFields" access="public" returnType="array" output="false" hint="Returns the fields for a module type.">
	<cfargument name="type" type="string" required="true" hint="Module type: Opportunities, Contacts, etc.">

	<cfset var result = "">
	<cfset var fieldList = "">
	<cfset var fields = arrayNew(1)>
	<cfset var s = "">
	<cfset var nullhandle = "">
	<cfset var options = "">
	<cfset var o = "">
	<cfset var fieldListItem = "">
	<cfset var oIndex = "">
		
	<cfinvoke webservice="#variables.endpoint#" method="get_module_fields" returnVariable="result" session="#variables.sessionid#">
		<cfinvokeargument name="module_name" value="#arguments.type#">
	</cfinvoke>
	<cfset fieldList = result.getModule_fields()>

	<cfloop index="fieldListItem" from="1" to="#arrayLen(fieldList)#">
		<cfset f = fieldList[fieldListItem]>
		<cfset s = structNew()>
		<cfset nullhandle = f.getDefault_value()>
		<cfif isDefined("nullhandle")>
			<cfset s.default = f.getDefault_value()>
		<cfelse>
			<cfset s.default = "">
		</cfif>
		<cfset s.label = f.getLabel()>
		<cfset s.name = f.getName()>
		<cfset s.options = structNew()>
				
		<cfset options = f.getOptions()>
		<cfloop index="oIndex" from="1" to="#arrayLen(options)#">
			<cfset o = options[oIndex]>
			<cfset s.options[o.getName()] = o.getValue()>
		</cfloop>

		<cfset s.required = f.getRequired()>
		<cfset s.type = f.getType()>
		
		<cfset arrayAppend(fields, s)>
	</cfloop>
	
	<cfreturn fields>
</cffunction>

<cffunction name="getList" access="public" returnType="query" output="false" hint="Returns a query of information.">
	<cfargument name="type" type="string" required="true" hint="What data to get: Opportunities, Contacts, etc.">
	<cfargument name="maxresults" type="numeric" required="false" default="0" hint="Max number of results, 0 is the default and will use SugarCRM default.">
	<cfargument name="query" type="string" required="false" default="" hint="Query to filter results.">
	<cfargument name="orderby" type="string" required="false" default="" hint="Field to sort by.">
	<cfargument name="offset" type="numeric" required="false" default="0" hint="Offset, used for paging.">
	<cfargument name="deleted" type="boolean" required="false" default="false" hint="If true, returns only deleted items.">
	<cfargument name="fields" type="string" required="false" default="" hint="A list of fields you want returned. SugarCRM will perform better if you filter the results.">
	<cfset var result = "">
	
	<cfinvoke webservice="#variables.endpoint#" method="get_entry_list" returnVariable="result" session="#variables.sessionid#">
		<cfinvokeargument name="module_name" value="#arguments.type#">
		<cfinvokeargument name="max_results" value="#arguments.maxresults#">
		<cfinvokeargument name="query" value="#arguments.query#">
		<cfinvokeargument name="order_by" value="#arguments.orderby#">
		<cfinvokeargument name="offset" value="#arguments.offset#">
		<cfinvokeargument name="select_fields" value="#listToArray(arguments.fields)#">
		<cfif arguments.deleted>
			<cfinvokeargument name="deleted" value="1">
		<cfelse>
			<cfinvokeargument name="deleted" value="0">
		</cfif>
	</cfinvoke>
	
	<cfreturn entryListToQuery(result)>
</cffunction>


<cffunction name="getUserId" access="public" returnType="string" output="false" hint="Returns the user id for the current user.">
	<cfset var result = "">
	<cfinvoke webservice="#variables.endpoint#" method="get_user_id" session="#variables.sessionid#" returnVariable="result">
	<cfreturn result>
</cffunction>

<cffunction name="login" access="public" returnType="void" output="false" hint="Attempts to login.">
	<cfset var result = "">
	<cfset var u = structNew()>
	<cfset var e = "">
	
	<cfset u.user_name = variables.username>
	<cfset u.password = hash(variables.password)>
	<cfset u.version = "1.0">

	<cfinvoke webservice="#variables.endpoint#" method="login" user_auth="#u#" application_name="ColdSugar" returnVariable="result">

	<cfset e = result.getError()>

	<cfif e.getNumber() neq 0>
		<cfthrow message="ColdSugar Login Error: #e.getNumber()#: #e.getName()#/#e.getDescription()#">
	</cfif>
	
	<cfset variables.sessionid = result.getId()>

</cffunction>

<cffunction name="logout" access="public" returnType="void" output="false" hint="Attempts to login.">

	<cfinvoke webservice="#variables.endpoint#" method="logout" session="#variables.sessionid#">

	<cfset variables.sessionid = "">

</cffunction>

<cffunction name="queryToStruct" access="private" returnType="struct" output="false" hint="Translates a query to a structure.">
	<cfargument name="q" type="query" required="true">
	<cfset var s = structNew()>
	<cfset var l = "">
	
	<cfloop index="l" list="#arguments.q.columnList#">
		<cfset s[l] = arguments.q[l][1]>
	</cfloop>

	<cfreturn s>
</cffunction>

<cffunction name="save" access="public" returnType="string" output="false" hint="Returns an object">
	<cfargument name="type" type="string" required="true" hint="What data to get: Opportunities, Contacts, etc.">
	<cfargument name="data" type="struct" required="true" hint="Object to save.">

	<cfset var a = arrayNew(1)>
	<cfset var k = "">
	<cfset var s = "">
	<cfset var e = "">
	
	<cfloop item="k" collection="#arguments.data#">
		<cfset s = structNew()>
		<cfset s.name = lcase(k)>
		<cfset s.value = arguments.data[k]>
		<cfset arrayAppend(a,s)>
	</cfloop>
	
	<cfinvoke webservice="#variables.endpoint#" method="set_entry" returnVariable="result" session="#variables.sessionid#">
		<cfinvokeargument name="module_name" value="#arguments.type#">
		<cfinvokeargument name="name_value_list" value="#a#">
	</cfinvoke>

	<cfset e = result.getError()>
	<cfif e.getNumber() neq 0>
		<cfthrow message="ColdSugar Save Error: #e.getNumber()#: #e.getName()#/#e.getDescription()#">
	</cfif>

	<cfreturn result.getId()>
	
</cffunction>

</cfcomponent>