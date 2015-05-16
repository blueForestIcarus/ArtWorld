import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'auth.dart';


int PORT = 1555;
Auth authenticator;

void main() {
     authenticator = new Auth();
     
     HttpServer.bind(InternetAddress.ANY_IP_V4, PORT).then((server) {
          server.listen((HttpRequest request) {
               try{
                    addCorsHeaders(request.response,request);

                    dispatch(request);
               }catch(e){
                    print("something went very wrong \n" + e);
                    request.response.write("something went very wrong");
                    request.response.close();
               }
          });
          print("server running on port $PORT \n");
     });
}

void dispatch(HttpRequest request){
     print("\n recieved request with method: " + request.method);
     
     if(request.method == "OPTIONS"){
          request.response.close();
     }
     
     else if(request.method == "LOGIN"){
          decodeJSON(request,(data){
               authenticator.loginRequestHandler(request, data);
          });
     }
     
     else if(request.method == "LOGOUT"){
          decodeJSON(request,(data) {
               authenticator.logoutHandler(request, data);
          });     
     }
     
     else if(request.method == "POST"){
          
     }
}

void decodeJSON(HttpRequest request, Function onDone){
     UTF8.decodeStream(request).then((string) {
          print("data: " + string);
          
          var data;
          
          try{
               data = JSON.decode(string);
               assert(data is Map);
          }catch(e){
               print("cannot read data as JSON -- aborting");
               request.response.write("invalid JSON");
               request.response.close();
               return;
          }
          
          onDone(data);
     });
}

//a temporary fix
void addCorsHeaders(HttpResponse res, HttpRequest req) {
     //print(req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Credentials", "true");
     res.headers.add("Access-Control-Allow-Origin", req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, HEAD, LOGIN, LOGOUT");
     res.headers.add("Access-Control-Allow-Headers", req.headers.value("Access-Control-Request-Headers"));
     res.headers.add("Access-Control-Expose-Headers", "status");

     //Access-Control-Max-Age
     //res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, TYPE, USER, PASS, STATUS");
}
