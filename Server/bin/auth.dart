import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as GoogleAuth;
import 'package:http/http.dart';

class Auth {
     HttpClient client;
     Client authClient;
     GoogleAuth.ClientId clientId;

     String id = "938657500643-uutcpvhpgo023ueueh10mg2vb6o2s7m6.apps.googleusercontent.com";
     String secret = "7vUgT2k3Hc81YIELivlA8DW5";
     String tokenURL = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=";
     
     int SERVER_ERROR = 500;
     int AUTH_FAILED = 401;
     int EXPIRED = 419;

     Map<String, User> users;
     
     Auth() {
          HttpClient client = new HttpClient();
          Client authClient = new Client();
          clientId = new GoogleAuth.ClientId(id, secret);
          
          users = new Map<String,User>();
     }

     void loginRequestHandler(HttpRequest request, String string) {
          print("request: " + string);
          var requestData = JSON.decode(string);
          String code = requestData["code"];
          String email = requestData["email"];

          GoogleAuth.obtainAccessCredentialsViaCodeExchange(authClient, clientId, code).then((GoogleAuth.AccessCredentials token) {
               client.getUrl(Uri.parse(tokenURL + token.accessToken.data)).then((HttpClientRequest request) {
                    return request.close();
               }).then((HttpClientResponse response) {
                    UTF8.decodeStream(response).then((String text) {
                         var responceData = JSON.decode(text);
                         if(email = responceData["email"]){
                              Map<String,String> credencials = addUser(responceData["email"],responceData["id"]);
                              var returnData = JSON.encode(credencials);
                              request.response.write(returnData);
                              
                         }else{
                              onLoginFailed(request,SERVER_ERROR);
                         }
                    });
               });
          }, onError: (e) {
               onLoginFailed(request,AUTH_FAILED);
          });
     }
     
     void onLoginFailed(request, int code){
          print("an error has occured, login failed");
          addCorsHeaders(request.response, request);
          request.response.write("authentication failed");
          request.response.statusCode = code;//unauthorised
          request.response.close();
     }
     
     Map<String,String> addUser(String email, String id){
          User user= new User(email,id);
          users[user.username] = user;
          return user.getCredencials();
     }
}

class User {
     String id;
     String email;
     String username;
     String code;
     DateTime expires;
     
     final int CODE_LENGTH = 33;
     final Random random = new Random();
     
     User(this.email, this.id){
          var split = email.split("@");
          if(split.length != 2){
               throw new Exception();
          }
          
          username = split[0];
          
          code = genCode();

          DateTime now = new DateTime.now();
          expires = now.add(new Duration(minutes: 30));
     }
     
     String genCode(){
          List<int> l = new List.generate(CODE_LENGTH, (i) => random.nextInt(256));
          return new String.fromCharCodes(l);
     }
     
     bool isValid(String c){
          return c==code;
     }
     
     bool isNotExpired(){
          return expires.isAfter(new DateTime.now());
     }
     
     Map<String,String> getCredencials(){
          return {"id":id, "email":email,"username":username,"code":code};
     }
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
