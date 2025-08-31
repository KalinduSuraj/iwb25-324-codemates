import ballerina/sql;
import ballerina/log;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

# Database connection utility for BinBuddy
# Provides database connection abstraction and common operations

# Database configuration
configurable string DB_HOST = "localhost";
configurable int DB_PORT = 3306;
configurable string DB_NAME = "binbuddy_db";
configurable string DB_USERNAME = "root";
configurable string DB_PASSWORD = "";

# Create a new database client
public function createDbClient() returns mysql:Client|error {
    mysql:Client mysqlClient = check new (
        host = DB_HOST,
        port = DB_PORT,
        database = DB_NAME,
        user = DB_USERNAME,
        password = DB_PASSWORD
    );
    return mysqlClient;
}

# Execute parameterized query
public function executeQuery(mysql:Client dbClient, sql:ParameterizedQuery query) returns sql:ExecutionResult|error {
    sql:ExecutionResult result = check dbClient->execute(query);
    return result;
}

# Execute SELECT query and return stream
public function queryDatabase(mysql:Client dbClient, sql:ParameterizedQuery query) returns stream<record {}, error?>|error {
    stream<record {}, error?> resultStream = dbClient->query(query);
    return resultStream;
}

# Health check for database - simplified version
public function isDatabaseHealthy() returns boolean {
    do {
        mysql:Client dbClient = check createDbClient();
        sql:ParameterizedQuery healthQuery = `SELECT 1 as health_check`;
        sql:ExecutionResult result = check dbClient->execute(healthQuery);
        error? closeResult = dbClient.close();
        log:printInfo("Database health check passed");
        return true;
    } on fail error e {
        log:printWarn("Database health check failed", e);
        return false;
    }
}
