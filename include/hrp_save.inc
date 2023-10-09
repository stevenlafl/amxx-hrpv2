/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Base (MYSQL) Saving Library
		
*/

#if defined _hrp_save_included
  #endinput
#endif
#define _hrp_save_included

#pragma library HRPSave


#include <hrp>
#include <sqlx>

new g_Error[512]

native Handle:hrp_sql();
native hrp_get_privileges(id);

stock SQL_QueryFmt(Handle:db_tuple, const fmt[], any:...)
{
	static query_buf[2048];
	vformat( query_buf, 2047, fmt, 3 );
	SQL_ThreadQuery( db_tuple, "QueryHandle", query_buf)
}

public QueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    // lots of error checking
    if(FailState == TQUERY_CONNECT_FAILED)
        return set_fail_state("Could not connect to SQL database.")
    else if(FailState == TQUERY_QUERY_FAILED)
        return set_fail_state("Query failed.")
   
    if(Errcode)
        return log_amx("Error on query: %s",Error)
   
    return PLUGIN_CONTINUE
}
stock SQL_CheckResult(Handle:Query, Error[], len )
{
	if( !SQL_Execute(Query) )
	{
		SQL_QueryError( Query, Error, len )
		set_fail_state( Error )
	}
}