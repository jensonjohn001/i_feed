import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_native_web/flutter_native_web.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:dynamic_theme/theme_switcher_widgets.dart';
//Project Files
import 'fab_with_icons.dart';
import 'fab_bottom_app_bar.dart';
import 'layout.dart';
import 'package:i_feed/model/model.dart';

void main() => runApp(new MyApp());
String url = "https://newsapi.org/v2/everything?sources=techradar&apiKey=ef5b910bb4a047d289c7366e96d9d9df";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
          primarySwatch: Colors.deepPurple,
          brightness: brightness,
        ),
        themedWidgetBuilder: (context, theme) {
          return new MaterialApp(
            title: 'Flutter Demo',
            theme: theme,
            home: new MyHomePage(title: 'Flutter Demo Home Page'),
          );
        }
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
            decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
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



class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String _lastSelected = 'TAB: 0';

  void _selectedTab(int index) {
    setState(() {
      _lastSelected = 'TAB: $index';
    });
  }

  void _selectedFab(int index) {
    setState(() {
      _lastSelected = 'FAB: $index';
    });
  }

  @override
  Widget build(BuildContext context) {

    if(_lastSelected == "TAB: 0"){
      return Scaffold(
        appBar: AppBar(
          title: Text("Global Feeds"),
            actions: <Widget>[
              new IconButton(icon: new Icon(Icons.brightness_4),
                onPressed: showChooser,
              ),
            ]

        ),
        body:new Center(
          //FutureBuilder is a widget that builds itself based on the latest snapshot
          // of interaction with a Future.
          child: new FutureBuilder<List<Article>>(
            future: downloadJSON(),
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
        bottomNavigationBar: FABBottomAppBar(
          centerItemText: '',
          color: Colors.grey,
          selectedColor: Colors.redAccent,
          notchedShape: CircularNotchedRectangle(),
          onTabSelected: _selectedTab,
          items: [
            FABBottomAppBarItem(iconData: Icons.rss_feed, text: 'Feeds'),
            FABBottomAppBarItem(iconData: Icons.account_balance, text: 'Home'),
            FABBottomAppBarItem(iconData: Icons.favorite, text: 'Loved'),
            FABBottomAppBarItem(iconData: Icons.more_vert, text: 'More'),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFab(
            context), // This trailing comma makes auto-formatting nicer for build methods.
      );


    }else{

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
            actions: <Widget>[
              new IconButton(icon: new Icon(Icons.brightness_4),
                onPressed: showChooser,
              ),
            ]
        ),
        body: Center(
          child: Text(
            _lastSelected,
            style: TextStyle(fontSize: 32.0),
          ),
        ),
        bottomNavigationBar: FABBottomAppBar(
          centerItemText: '',
          color: Colors.grey,
          selectedColor: Colors.redAccent,
          notchedShape: CircularNotchedRectangle(),
          onTabSelected: _selectedTab,
          items: [
            FABBottomAppBarItem(iconData: Icons.rss_feed, text: 'Feeds'),
            FABBottomAppBarItem(iconData: Icons.account_balance, text: 'Home'),
            FABBottomAppBarItem(iconData: Icons.favorite, text: 'Loved'),
            FABBottomAppBarItem(iconData: Icons.more_vert, text: 'More'),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFab(
            context), // This trailing comma makes auto-formatting nicer for build methods.
      );

    }


  }

  Widget _buildFab(BuildContext context) {
    final icons = [ Icons.sms, Icons.mail, Icons.phone ];
    return AnchoredOverlay(
      showOverlay: true,
      overlayBuilder: (context, offset) {
        return CenterAbout(
          position: Offset(offset.dx, offset.dy - icons.length * 35.0),
          child: FabWithIcons(
            icons: icons,
            onIconTapped: _selectedFab,
          ),
        );
      },
      child: FloatingActionButton(
        onPressed: () { },
        tooltip: 'Increment',
        child: Icon(Icons.add),
        elevation: 2.0,
      ),
    );
  }


  void showChooser() {
    showDialog(context: context, builder: (context) {
      return new BrightnessSwitcherDialog(
        onSelectedTheme: (brightness) {
          DynamicTheme.of(context).setBrightness(brightness);
        },
      );
    });
  }


  void changeBrightness() {
    DynamicTheme.of(context).setBrightness(Theme.of(context).brightness == Brightness.dark? Brightness.light: Brightness.dark);
  }

  void changeColor() {
    DynamicTheme.of(context).setThemeData(new ThemeData(
        primaryColor: Theme.of(context).primaryColor == Colors.indigo? Colors.red: Colors.indigo
    ));
  }



}