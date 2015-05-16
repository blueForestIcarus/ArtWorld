import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart';


int port = 1555;
HttpClient client = new HttpClient();
Client authClient = new Client();

void main() {
     HttpServer.bind(InternetAddress.ANY_IP_V4, port).then((server) {
          server.listen((HttpRequest request) {
               print(request.method);
               if (request.method == "LOGIN") {
                    UTF8.decodeStream(request).then((data) {
                         verifyCode(request, data);
                    });
               }
               else if (request.method == "OPTIONS") {
                    addCorsHeaders(request.response, request);
                    request.response.close();
               }
               
          });
          print("server running on port $port \n");
     });
}


void verifyCode(HttpRequest request, String data) {
     print("request: " + data);

     auth.ClientId clientId = new auth.ClientId("938657500643-uutcpvhpgo023ueueh10mg2vb6o2s7m6.apps.googleusercontent.com", "7vUgT2k3Hc81YIELivlA8DW5");
     auth.obtainAccessCredentialsViaCodeExchange(authClient, clientId, data).then((auth.AccessCredentials token) {
          client.getUrl(Uri.parse("https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=" + token.accessToken.data)).then((HttpClientRequest request) {
               return request.close();
          }).then((HttpClientResponse response) {
               UTF8.decodeStream(response).then((String text) {
                    print("responce: " +text);
                    addCorsHeaders(request.response, request);
                    request.response.write(text);
                    request.response.close();
               });
          });
     },onError: (e){
          print("an error has occured");
           addCorsHeaders(request.response, request);
           request.response.write("authentication failed");
           request.response.statusCode = 401;//unauthorised
           request.response.close();
     });



}

//a temporary fix
void addCorsHeaders(HttpResponse res, HttpRequest req) {
     //print(req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Credentials", "true");
     res.headers.add("Access-Control-Allow-Origin", req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, HEAD, LOGIN");
     res.headers.add("Access-Control-Allow-Headers", req.headers.value("Access-Control-Request-Headers"));
     res.headers.add("Access-Control-Expose-Headers", "status");

     //Access-Control-Max-Age
     //res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, TYPE, USER, PASS, STATUS");
}
