import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_native_web/flutter_native_web.dart';

String url = "https://newsapi.org/v2/everything?sources=techcrunch&apiKey=ef5b910bb4a047d289c7366e96d9d9df";

class Feed {
  final String status;
  final List<Article> articles;

  Feed({
    this.status,
    this.articles
  });

  factory Feed.fromJson(Map<String, dynamic> parsedJson){
    var list = parsedJson['articles'] as List;
    print(list.runtimeType);
    List<Article> articlesList = list.map((i) => Article.fromJson(i)).toList();

    return Feed(
        status:parsedJson['status'],
        articles:articlesList
    );
  }

}

class Article {
  final String title;
  final String description, urlToImage, url, publishedAt;

  Article({
    this.title,
    this.description,
    this.urlToImage,
    this.url,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> jsonData) {
    return Article(
      title: jsonData['title'],
      description: jsonData['description'],
      urlToImage: jsonData['urlToImage'],
      url: jsonData['url'],
      publishedAt: jsonData['publishedAt'],
    );
  }
}



class CustomListView extends StatelessWidget {
  final List<Article> articles;

  CustomListView(this.articles);

  Widget build(context) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, int currentIndex) {
        return createViewItem(articles[currentIndex], context);
      },
    );
  }



  Widget createViewItem(Article articles, BuildContext context) {

    var dateFromApi = articles.publishedAt;
    var date = DateTime.parse(dateFromApi);
    var formatter = new DateFormat('dd-MMM-yyyy hh:mm:ss a');
    String formattedTime = formatter.format(date);

    return new ListTile(
        title: new Card(
          elevation: 5.0,
          child: new Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.orange)),
            padding: EdgeInsets.all(20.0),
            margin: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Padding(
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/loader.gif',
                    image: articles.urlToImage,
                  ),
                  padding: EdgeInsets.only(bottom: 8.0),
                ),
                new Wrap(
                    direction: Axis.horizontal,children: <Widget>[
                  Padding(
                      child: Text(
                        articles.title,
                        style: new TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.left,
                      ),
                      padding: EdgeInsets.all(1.0)),
                  Text(" - "),
                  Padding(
                      child: Text(

                        formattedTime,
                        style: new TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.left,
                      ),
                      padding: EdgeInsets.all(1.0)),
                ]),
              ],
            ),
          ),
        ),
        onTap: () {
          //We start by creating a Page Route.
          //A MaterialPageRoute is a modal route that replaces the entire
          //screen with a platform-adaptive transition.
          var route = new MaterialPageRoute(
            builder: (BuildContext context) =>
            new SecondScreen(value: articles),
          );
          //A Navigator is a widget that manages a set of child widgets with
          //stack discipline.It allows us navigate pages.
          Navigator.of(context).push(route);
        });
  }
}

//Future is n object representing a delayed computation.
Future<List<Article>> downloadJSON() async {
  final jsonEndpoint = url;

  final response = await get(jsonEndpoint);

  if (response.statusCode == 200) {
    print(response.body);
    Map resBody = json.decode(response.body);
    if(resBody.containsKey("articles")) {
      List articles = resBody["articles"];
      return articles
          .map((articles) => new Article.fromJson(articles))
          .toList();
    }else{
      throw Exception('We were not able to successfully download the json data.');
    }
  } else
    throw Exception('We were not able to successfully download the json data.');

}

class SecondScreen extends StatefulWidget {
  final Article value;

  SecondScreen({Key key, this.value}) : super(key: key);

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {

  WebController webController;
  void onWebCreated(webController) {
    this.webController = webController;
    this.webController.loadUrl('${widget.value.url}');
    this.webController.onPageStarted.listen((url) =>
        print("Loading $url")
    );
    this.webController.onPageFinished.listen((url) =>
        print("Finished loading $url")
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Detail Page')),
      body: new Container(
        child: new Center(
          child: Column(
            children: <Widget>[
              Padding(
                child: new Text(
                  '${widget.value.title}',
                  style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
                padding: EdgeInsets.all(10.0),
              ),
              Padding(
                //`widget` is the current configuration. A State object's configuration
                //is the corresponding StatefulWidget instance.
                child: Image.network( '${widget.value.urlToImage}'),
                padding: EdgeInsets.only(bottom: 5.0),
              ),
              Padding(
                child:new Container(
                    child: new FlutterNativeWeb(onWebCreated: onWebCreated),
                    height: 300.0,
                    width: 500.0,
                    alignment:Alignment.center
                ),
                padding: EdgeInsets.all(10.0),
              )
            ],   ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
          primarySwatch: Colors.green,
          brightness: Brightness.light,
          accentColor: Colors.red
      ),
      home: new Scaffold(
        appBar: new AppBar(title: const Text('JSON Images Text'),
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.brightness_3),
              onPressed: (){},
            ),
          ],
        ),

        body: new Center(
          //FutureBuilder is a widget that builds itself based on the latest snapshot
          // of interaction with a Future.
          child: new FutureBuilder<List<Article>>(
            future: downloadJSON(),
            //we pass a BuildContext and an AsyncSnapshot object which is an
            //Immutable representation of the most recent interaction with
            //an asynchronous computation.
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Article> spacecrafts = snapshot.data;
                return new CustomListView(spacecrafts);
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              //return  a circular progress indicator.
              return new CircularProgressIndicator();
            },
          ),

        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}