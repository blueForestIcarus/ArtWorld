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
     String tokenURL = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=";//this isnt the best option, but it works
     
     int SERVER_ERROR = 500;
     int AUTH_FAILED = 401;
     int EXPIRED = 419;

     Map<String, User> users;
     
     Auth() {
          client = new HttpClient();
          authClient = new Client();
          clientId = new GoogleAuth.ClientId(id, secret);
          
          users = new Map<String,User>();
     }

     void loginRequestHandler(HttpRequest request, Map data) {
          String code = data["code"];
          String id = data["id"];

          GoogleAuth.obtainAccessCredentialsViaCodeExchange(authClient, clientId, code).then((GoogleAuth.AccessCredentials token) {
               client.getUrl(Uri.parse(tokenURL + token.accessToken.data)).then((HttpClientRequest get) {
                    return get.close();
               }).then((HttpClientResponse response) {
                    UTF8.decodeStream(response).then((String text) {
                         print("token info: " + text);
                         var responseData = JSON.decode(text);
                         if(responseData["id"] == id){
                              Map<String,String> credencials = addUser(responseData["email"],responseData["user_id"]);
                              var returnData = JSON.encode(credencials);
                              print("return data: " + returnData);
                              request.response.write(returnData);
                              request.response.close();     
                         }else{
                              onLoginFailed(request,AUTH_FAILED);
                         }

                    }).catchError((e)=>onLoginFailed(request,SERVER_ERROR));
               });
          }, onError: (e) {
               print(e);
               onLoginFailed(request,AUTH_FAILED);
          });
     }
     
     void onLoginFailed(HttpRequest request, int code){
          print("an error has occured, login failed - " + code.toString());
          request.response.statusCode = code;
          request.response.write("authentication failed");
          request.response.close();
     }
     
     void logoutHandler(HttpRequest request, Map data) {
          String code = data["code"];
          String username = data["username"];
          String email = data["email"];
          
          User user = users[username];
          
          if(user != null && user.isValid(code)){
               users.remove(username);
          }

          request.response.write("logged out successfully");
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
