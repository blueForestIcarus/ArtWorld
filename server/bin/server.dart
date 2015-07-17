import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'auth.dart';


int PORT = 1555;
Auth authenticator;
List<String> pages = [];
String path = "/home/http/artworld/resources/";

void main() {
     authenticator = new Auth();

	 Directory users = new Directory(path + 'users');

	 if(users.existsSync()){
      for(Directory user in users.listSync()){
          var p = new Directory(user.path + '/pages')..createSync();
          for(Directory page in p.listSync()){
              pages.add(page.path.split("/").last + "@" + user.path.split("/").last);
          }
      }
      print("Pages:");
      print(pages);
      print("");

	 }else{
		  throw new Exception("Resource directory path: " + users.path + " does not exist");
	 }

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

	 else if(request.method == "SEARCH"){
		//artworld.mechasdf.com/search/<text>
	  List<String> results = [];

		if(
		  request.uri.pathSegments[0]=="search" &&
		  request.uri.pathSegments.length == 3 &&
		  request.uri.pathSegments[1]=="page")
		{
			String text = request.uri.pathSegments[2];
			for(String p in pages){
				if(p.indexOf(text) != -1){
					results.add(p);
				}
			}
		}

		print("results: " + results.toString());
    request.response.write(JSON.encode(results));
    request.response.close();

	 }

     else if(request.method == "POST"){
          String username = request.headers.value("username");
          String code = request.headers.value("code");

          if( username == null || code == null ){
               print("auth failed, no credencials");
               request.response.statusCode = 401;
               request.response.write("must send auth. credencials");
               request.response.close();
               return;

          }

          if(! authenticator.authenticate(username, code)){
               print("auth failed: " + username + " " + code);
               request.response.statusCode = 401;
               request.response.write("authentication failed" + username + " " + code);
               request.response.close();
               return;

          }

          if(request.uri.pathSegments[0] != "post" || request.uri.pathSegments[1] != "page" || request.uri.pathSegments.length != 4){
               print("invalid path: " + request.uri.path);
               request.response.statusCode = 401;
               request.response.write("invalid path");
               request.response.close();
               return;
          }

          String pageName = request.uri.pathSegments[2];
          String type = request.uri.pathSegments[3];
          String filename;
          if(type == "xml"){
               filename = "info.xml";
          }else if(type == "img"){
               filename = "img.png";
          }else if(type == "map"){
               filename = "map.png";
          }

          File file = new File("/home/sb/www/artworld/resources/users/" + username + "/pages/" + pageName + "/" + filename);

          //disabled
          if(file.existsSync() && false){
               print("resource already exists: " + request.uri.path);
               request.response.statusCode = 401;
               request.response.write("resource already exists");
               request.response.close();
               return;
          }

          List<int> bytes = [];
          request.listen((data) {
               bytes.addAll(data);
          })..onDone((){
               print("writing to new resource: " + file.path);
               file.create(recursive:true).then((file){
                    file.writeAsBytes(bytes).catchError((e){
                         print("error writing file " + e);
                         request.response.statusCode = 500;
                         request.response.write("error in writing data");
                         request.response.close();
                    });

               });
          })..onError( (e) {
               print("error in retrieving data: " + e);
               request.response.statusCode = 500;
               request.response.write("error in retrieving data");
               request.response.close();
          });
     }

}

void decodeJSON(HttpRequest request, Function onDone){
     UTF8.decodeStream(request).then((string) {
          print("data: " + string);

          Map data;

          try{
               data = JSON.decode(string);
          }catch(e){
               print("cannot read data as JSON -- aborting");
               request.response.write("invalid JSON");
               request.response.close();
               return;
          }

          onDone(data);
     }).catchError((e) => print("could not decode json: " + e));
}

//a temporary fix
void addCorsHeaders(HttpResponse res, HttpRequest req) {
     //print(req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Credentials", "true");
     res.headers.add("Access-Control-Allow-Origin", req.headers.value("Origin"));
     res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, HEAD, LOGIN, LOGOUT, SEARCH");
     res.headers.add("Access-Control-Allow-Headers", req.headers.value("Access-Control-Request-Headers"));
     res.headers.add("Access-Control-Expose-Headers", "status");

     //Access-Control-Max-Age
     //res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, TYPE, USER, PASS, STATUS");
}
