import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_native_web/flutter_native_web.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:dynamic_theme/theme_switcher_widgets.dart';
import 'package:flare_flutter/flare_actor.dart';
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
            FABBottomAppBarItem(iconData: Icons.accessibility, text: 'Story'),
            FABBottomAppBarItem(iconData: Icons.favorite, text: 'Loved'),
            FABBottomAppBarItem(iconData: Icons.more_vert, text: 'More'),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFab(
            context), // This trailing comma makes auto-formatting nicer for build methods.
      );


    }else if(_lastSelected == "TAB: 1"){//story
      return storyPage();
    }else if(_lastSelected == "TAB: 2"){//Flare anim
      return flarePage();
    } else{
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
            FABBottomAppBarItem(iconData: Icons.accessibility, text: 'Story'),
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


  Widget storyPage(){
    return Scaffold(
      appBar: AppBar(
          title: Text("Story of boy"),
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.brightness_4),
              onPressed: showChooser,
            ),
          ]
      ),
      body: new Container(
          child: new SingleChildScrollView(
              child: new ConstrainedBox(
                constraints: new BoxConstraints(),
                child: new Column(children: <Widget>[

                  new Container(
                    padding:
                    EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
                    child: new Text(
                      'ഒരു ഗുണപാഠ കഥ',
                      style: new TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  new Image.network(
                    'https://media.giphy.com/media/veZF9QdPNjuhi/source.gif',
                  ),
                  new Container(
                    child: new Text(
                      '.. ഒരിടത്ത് ഒരുകൃഷിക്കാരനു ഒരു കഴുത ഉണ്ടായിരുന്നു ,ഒരു ദിവസം ഈ കഴുത ഒരു കുഴിയില്‍ വീണു.'
                          'വളരെ ആഴമുള്ള കുഴിയായിരുന്നു .അത് കര കയറാന്‍ കഴിയാതെ കഴുത  കുഴിയില്‍ കിടന്നു  ദയനീയമായി നില വിളിച്ചു ..'
                          '\n\nകഴുതയുടെ കരച്ചില്‍ കേട്ടു കൃഷിക്കാരന്‍ വന്നു നോക്കി ഇതിനെ കുഴിയില്‍ നിന്നു പുറത്തു കൊണ്ട് വരുന്നത് ശ്രമകരമായ ജോലി തന്നെ . പോരെങ്കില്‍ .പ്രായമായ കഴുതയും .'
                          'വേറേതെ പണം ചിലവാക്കുന്നതെന്തിന്…? ഇതിനെ ആ കുഴിയില്‍തന്നെ ഇട്ടു മൂടിയേക്കാം .'
                          'അയാള്‍ അങ്ങനെ ചിന്തിച്ചു.തന്‍റെ അയല്‍വാസികളെ വിളിച്ച് വരുത്തി .ആ കഴുതയുടെ മേല്‍ മണ്ണിട്ട് മൂടുവാന്‍ അയാളെ സഹായിക്കണമെന്ന് പറഞ്ഞു .അവരെല്ലാവരും .തൂംബയും ,മണ്‍വെട്ടിയും ഒക്കെ കൊണ്ടുവന്നു ..'
                          'കുഴിയില്‍ കിടക്കുന്ന കഴുതയുടെ മുകളിലേക്കു മണ്ണ് കോരിയിടുവാനാരംഭിച്ചു . കഴുതയ്ക്ക് മനസിലായി ഇവെരെല്ലാവരും ചേര്‍ന്ന് രക്ഷിയ്ക്കുന്നതിന് പകരം  തന്നെ കുഴിയിലിട്ട് മൂടുവാന്‍ പോകുകയാണെന്ന് .'
                          '.അതിന്‍റെ കരച്ചില്‍ ഉച്ചത്തിലായി .പിന്നെ പെട്ടെന്നു തന്നെ എല്ലാവരെയും അത്ഭുത പ്പെടുത്തി കൊണ്ട് .കഴുതയുടെ കരച്ചില്‍ നിന്നു .ആള്‍ക്കാര്‍ മണ്ണ് വെട്ടി കഴുതയുടെ പുറത്തെയ്ക്കിട്ടു..കുറെ മണ്ണ് വെട്ടിയിട്ടു കഴിഞ്ഞു കൃഷിക്കാരന്‍ കുഴിയിലേക്ക് നോക്കി അവിടെ കണ്ട കാഴ്ച അയാളെ അംബരപ്പിച്ചു..'
                          'കൃഷിക്കാരനും കൂട്ടാളികളും മണ്ണ് വെട്ടി കഴുതയുടെ പുറത്തേയ്ക്കിടുമ്പോ ഓരോ പ്രാവശ്യവും തന്‍റെ പുറത്തേയ്ക്ക് വീഴുന്ന മണ്ണ് കുടഞ്ഞു കളഞ്ഞു കൊണ്ട് കഴുത മണ്ണിന്റെ പുറത്തു കയറി നില്ക്കും ..അങ്ങനെ കുഴിയില്‍ മണ്ണ് നിറഞ്ഞപ്പോള്‍ .കഴുത ഓരോ സ്റ്റെപ്പുമ് കയറി കയറി കുഴിയുടെ പുറത്തെത്തി.. '
                          'പുറത്തെത്തിയ കഴുത തന്നെ കുഴിയിലിട്ട് മൂടാന്‍ ശ്രമിച്ച കൃഷിക്കാരനെ കടിച്ചു മുറിവേല്‍പ്പിച്ചു .കഴുതയുടെ  കടികൊണ്ടു .മുറിവേറ്റ ഭാഗം പഴുത്തു സെപ്റ്റിക്കായി..അയാള്‍ തീവ്രമായ വേദനയനുഭവിച്ചു മരിച്ചു …'
                          '.ഈ കഥയിലെ ആദ്യത്തെ ഗുണപാഠം ഈ ലോക ജീവിതത്തില്‍ നമ്മുടെ മുകളിലേക്കു ചിലപ്പോള്‍ മറ്റുള്ളവര്‍ അഴുക്കും ചെളിയും ഒക്കെ വാരിയിട്ടേക്കാം ,എന്നാല്‍ അതിനെ കുടഞ്ഞു കളഞ്ഞുകൊണ്ട് ഓരോ സ്റ്റെപ്പും മുന്‍പോട്ടു വയ്ക്കാന്‍ പടിയ്ക്കണം .പ്രശ്നങ്ങളില്ലാത്ത ജീവിതം ഇല്ല .പ്രശ്നങ്ങള്‍ വരുമ്പോ അതിനെ അതി ജീവിയ്ക്കാന്‍ പടിയ്ക്കുക .അതില്‍ നിന്നുംപ്രശ്ന രഹിതമായ ജീവിതത്തിലേയ്ക്ക് വഴിയൊരുക്കാന്‍ ശ്രമിയ്ക്കണം .'
                          'ഗുണപാഠം -2 –നമ്മള്‍ എപ്പോഴെങ്കിലും ഒരു തെറ്റ് ചെയ്ത് അത് മൂടിവച്ചാലും .ഒരു ദിവസം അത് മറനീക്കി പുറത്തുവരും . ഒരു നാള്‍ നമ്മളെ തിരിഞ്ഞു കടിയ്ക്കുക തന്നെ ചെയ്യും .'
                          '-  കിട്ടിയ ജീവിതം സന്തോഷ പൂര്‍ണ്ണമാക്കാന്‍ ചില ലളിതമായ വഴികള്‍ .1-ഹൃദയത്തിലെ   വെറുപ്പും വിദ്വേഷവും  പുറത്തുകളഞ്ഞു എല്ലാവരോടും ക്ഷമിയ്ക്കാന്‍ പടിയ്ക്കുക . 2- സംഭവിയ്ക്കാന്‍ സാദ്യതയില്ലാത്ത കാര്യങ്ങളെക്കുറിച്ചോര്‍ത്തു അനാവശ്യമായി ടെന്‍ഷന്‍ ആവാതിരിയ്ക്കുക . 3 -നമ്മള്‍ ആയിരിയ്ക്കുന്ന അവസ്ഥ എന്താണോ അതിന്റ്റെ പരിമിതിയില്‍ നിന്നു ജീവിയ്ക്കാന്‍ പടിയ്ക്കുക . 4-മറ്റുള്ളവരില്‍ നിന്നും സഹായം പ്രതീക്ഷിയ്ക്കാതെ കഴിയുമെങ്കില്‍ അര്‍ഹതയുള്ളവരെ സഹായിക്കുക..ഇത്രയും ചെയ്താല്‍ നമ്മുടെ ജീവിതം സന്തോഷപ്രദ മാകും എന്ന കാര്യ ത്തില്‍ സംശയം വേണ്ട. (ഒരു ഇംഗ്ലിഷ് കഥയുടെ വിവര്‍ത്തനം) by സിബി തോമസ് .',

                      style: new TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,

                      ),textAlign: TextAlign.left,
                    ),padding: EdgeInsets.all(10.0),
                  )
                ]),
              ))),
      bottomNavigationBar: FABBottomAppBar(
        centerItemText: '',
        color: Colors.grey,
        selectedColor: Colors.redAccent,
        notchedShape: CircularNotchedRectangle(),
        onTabSelected: _selectedTab,
        items: [
          FABBottomAppBarItem(iconData: Icons.rss_feed, text: 'Feeds'),
          FABBottomAppBarItem(iconData: Icons.accessibility, text: 'Story'),
          FABBottomAppBarItem(iconData: Icons.favorite, text: 'Loved'),
          FABBottomAppBarItem(iconData: Icons.more_vert, text: 'More'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFab(
          context), // This trailing comma makes auto-formatting nicer for build methods.
    );

  }//widget story

  Widget flarePage(){

    /* child: FlareActor(
    "assets/boy.flr",
    animation: "squats",//"step","wait","squats","steps"
    ), */

    return Scaffold(
      appBar: AppBar(
          title: Text("Flare animation"),
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.brightness_4),
              onPressed: showChooser,
            ),
          ]
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {

                  });
                },
                child: FlareActor(
                  "assets/boy.flr",
                  alignment: Alignment.center,
                  animation: "squats",
                  fit: BoxFit.contain,

                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {

                },
                child: FlareActor(
                  "assets/boy.flr",
                  alignment: Alignment.center,
                  animation: "steps",
                  fit: BoxFit.contain,

                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {

                },
                child: FlareActor(
                  "assets/boy.flr",
                  alignment: Alignment.center,
                  animation: "step",
                  fit: BoxFit.contain,

                ),
              ),
            ),
          ],
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
          FABBottomAppBarItem(iconData: Icons.accessibility, text: 'Story'),
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