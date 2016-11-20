<!---
This is an example file. 
You must have your own sugar url. You can sign up for a free trial. Take your main url and simply add soap.php?wsdl to the end.
Obviously the username and password much change as well.
This doesn't demonstrate everything - be sure to skim the CFC for more info.
--->

<cfset coldsugar = createObject("component", "sugarcrm").init("http://eval.sugarondemand.com/xxx/soap.php?wsdl", "admin", "foo", true)>

<cfoutput>

<p>
userid=#coldsugar.getUserId()#
</p>

<cfdump var="#coldsugar.getList('Opportunities')#" label="Opportunities">

<cfset q = "opportunities.name LIKE 'TI%'">
<cfdump var="#coldsugar.getList(type='Opportunities',query=q)#" label="query=#q#">

<cfdump var="#coldsugar.getList(type='Opportunities',orderby='amount_usdollar')#" label="sort by amount_usdollar">

<cfdump var="#coldsugar.getList(type='Opportunities',deleted=true)#" label="deleted">

<cfdump var="#coldsugar.getList(type='Opportunities',fields='name,amount_usdollar')#" label="Just name and amount_usdollar">

<cfdump var="#coldsugar.getList('Contacts')#" label="Contacts">

<cfdump var="#coldsugar.getList('Accounts')#" label="Accounts">
<cfabort>

<cfdump var="#coldsugar.getList('Documents')#" label="Documents">

<cfdump var="#coldsugar.getList('Calls')#" label="Calls">

<cfdump var="#coldsugar.getList('Meetings')#" label="Meetings">

<cfdump var="#coldsugar.getList('Tasks')#" label="Tasks">

<cfdump var="#coldsugar.getList('Notes')#" label="Notes">

<cfdump var="#coldsugar.getFields('Emails')#" label="Email Fields">


<cfset emails = coldsugar.getList('Emails')>
<cfdump var="#emails#" label="Emails">

<cfset email = coldsugar.get('Emails', emails.id[1])>
<cfdump var="#email#" label="Emails">


<cfset email.status = 'replied'>
<cfset r = coldsugar.save('Emails',email)>
<p>
Result of save is #r#
</p>

<cfset coldsugar.logout()>

<p>
Done with tests.
</p>
</cfoutput>