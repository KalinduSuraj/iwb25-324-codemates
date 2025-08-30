import ballerina/http;

service /hello on new http:Listener(8080) {
    resource function get greeting() returns string {
        return "Hello from BinBuddy!";
    }
}
