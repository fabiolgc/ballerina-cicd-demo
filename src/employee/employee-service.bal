import ballerina/http;
import ballerina/log;
import ballerinax/docker;

@docker:Expose{}
listener http:Listener httpListener = new(9090);

map<json> employeeMap = {};

// RESTful service.
@docker:Config {
    registry:"index.docker.io/fabiowso2",
    name:"ballerina-cicd-demo",
    tag:"1.0"
}

@http:ServiceConfig { basePath: "/employee" }
service employeeMgt on httpListener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/{employeeId}"
    }
    resource function findEmployee(http:Caller caller, http:Request req, string employeeId) {
        
        json? payload = employeeMap[employeeId];
        http:Response response = new;
        if (payload == null) {
            payload = "Employee : " + employeeId + " cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint payload);

        // Send response to the client.
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function addEmployee(http:Caller caller, http:Request req) {
        http:Response response = new;
        var employeeReq = req.getJsonPayload();
        if (employeeReq is json) {
            string employeeId = employeeReq.Employee.ID.toString();
            employeeMap[employeeId] = employeeReq;

            // Create response message.
            json payload = { status: "Employee Created.", employeeId: employeeId };
            response.setJsonPayload(untaint payload);

            // Set 201 Created status code in the response message.
            response.statusCode = 201;
            // Set 'Location' header in the response message.
            // This can be used by the client to locate the newly added employee.
            response.setHeader("Location", 
                "http://localhost:9090/employee/" + employeeId);

            // Send response to the client.
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    }
}