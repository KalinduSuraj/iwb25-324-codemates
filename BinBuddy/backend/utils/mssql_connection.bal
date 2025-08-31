// import ballerina/sql;
import ballerina/log;
import ballerinax/mssql;
import ballerinax/mssql.driver as _;

# SQL Server Database connection utility for BinBuddy
# Provides SQL Server database connection abstraction and common operations

# SQL Server Database configuration
configurable string MSSQL_HOST = "localhost";
configurable int MSSQL_PORT = 1433;
configurable string MSSQL_DATABASE = "binbuddy_db";
configurable string MSSQL_USERNAME = "";
configurable string MSSQL_PASSWORD = "";
configurable string MSSQL_INSTANCE = "MSSQLLocalDB";
configurable boolean USE_WINDOWS_AUTH = true;

# Create a new SQL Server database client
public function createMSSQLClient() returns mssql:Client|error {
    mssql:Client mssqlClient;
    
    if USE_WINDOWS_AUTH {
        # Using Windows Authentication for LocalDB
        string connectionString = "server=(localdb)\\" + MSSQL_INSTANCE + ";database=" + MSSQL_DATABASE + ";integratedSecurity=true;encrypt=false;";
        mssqlClient = check new (connectionString);
    } else {
        # Using SQL Server authentication
        mssqlClient = check new (
            host = MSSQL_HOST,
            port = MSSQL_PORT,
            database = MSSQL_DATABASE,
            user = MSSQL_USERNAME,
            password = MSSQL_PASSWORD
        );
    }
    return mssqlClient;
}

# Execute parameterized query
public function executeMSSQLQuery(mssql:Client dbClient, sql:ParameterizedQuery query) returns sql:ExecutionResult|error {
    sql:ExecutionResult result = check dbClient->execute(query);
    return result;
}

# Execute SELECT query and return stream
public function queryMSSQLDatabase(mssql:Client dbClient, sql:ParameterizedQuery query) returns stream<record {}, error?>|error {
    stream<record {}, error?> resultStream = dbClient->query(query);
    return resultStream;
}

# Health check for SQL Server database
public function isMSSQLDatabaseHealthy() returns boolean {
    do {
        mssql:Client dbClient = check createMSSQLClient();
        sql:ParameterizedQuery healthQuery = `SELECT 1 as health_check`;
        sql:ExecutionResult result = check dbClient->execute(healthQuery);
        error? closeResult = dbClient.close();
        log:printInfo("SQL Server database health check passed");
        return true;
    } on fail error e {
        log:printWarn("SQL Server database health check failed", e);
        return false;
    }
}

# Get database connection info for debugging
public function getMSSQLConnectionInfo() returns string {
    string connectionInfo = "SQL Server LocalDB Connection:\n" +
    "    Instance: " + MSSQL_INSTANCE + "\n" +
    "    Database: " + MSSQL_DATABASE + "\n" +
    "    Authentication: " + (USE_WINDOWS_AUTH ? "Windows Auth" : "SQL Auth");
    return connectionInfo;
}
