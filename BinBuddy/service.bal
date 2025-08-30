import ballerina/http;

listener http:Listener helloListener = new(8080);

service /hello on helloListener {

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["*"],
            allowMethods: ["GET", "POST"]
        }
    }
    resource function get greeting() returns string {
        return "Hello from BinBuddy!";
    }
}
