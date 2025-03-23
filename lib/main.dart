import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'tinder.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: "Spotify Album Viewer",
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

  Route<dynamic> _onGenerateRoute(RouteSettings settings){
    final String clientId = "981553fa76a846a0898364161fb1f2fa";
    final String clientSecret = '63ac0627a72b4828ab884b3f7f0de482';
    final String redirectUri = 'http://localhost:8888/callback';

    final uri = Uri.parse(settings.name!);
    if (uri.path == '/callback'){
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      return MaterialPageRoute(
          builder: (context) => SpotifyAuthCallback(code: code, state: state, clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
      );
    }
    return MaterialPageRoute(builder: (context) => SpotifyAuth(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri));
  }

/*class MyWebView extends StatefulWidget {
  final String clientId = "981553fa76a846a0898364161fb1f2fa";
  final String clientSecret = '63ac0627a72b4828ab884b3f7f0de482';
  final String redirectUri = 'http://localhost:8888/callback';

  @override
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  WebViewController _controller = WebViewController();
  String currentUrl = 'https://localhost:8888';

  @override
  void initState(){
    super.initState();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    final uri = Uri.parse(currentUrl);
    final comparedUri = Uri.parse('https://localhost:8888');
    if (uri == comparedUri) {
      SpotifyAuth(clientId: widget.clientId,
        clientSecret: widget.clientSecret,
        redirectUri: widget.redirectUri,
        controller: _controller,);
    } else {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      SpotifyAuthCallback(code: code, state: state, clientId: widget.clientId, clientSecret: widget.clientSecret, redirectUri: widget.redirectUri);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}*/

class SpotifyAuth extends StatefulWidget {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;
  //WebViewController controller;

  SpotifyAuth({this.clientId, this.clientSecret, this.redirectUri});

  @override
  _SpotifyAuthState createState() => _SpotifyAuthState();
}

class _SpotifyAuthState extends State<SpotifyAuth> {

  String generateRandomString(int length) {
    const characters = 'qwertzuipasdfghjklyxcvbnmQWERTZUIOPASDFGHJKLYXCVBNM0123456789';
    final random = Random.secure();
    return List.generate(
        length, (index) => characters[random.nextInt(characters.length)])
        .join();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> login() async {
    final state = generateRandomString(16);
    final scope = 'user-read-playback-state';
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'response_type': 'code',
      'client_id': widget.clientId,
      'scope': scope,
      'redirect_uri': widget.redirectUri,
      'state': state,
    });

    redirectToSpotify(url);
  }

  void redirectToSpotify(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Login")
      ), body: Center(
      child: ElevatedButton(
          onPressed: () => login(), child: Text('Login with Spotify')),
    ),
    );
  }
}

class SpotifyAuthCallback extends StatefulWidget{
  final String? code;
  final String? state;
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;

  SpotifyAuthCallback({this.code, this.state, this.clientId, this.clientSecret, this.redirectUri});

  @override _SpotifyAuthCallbackState createState() => _SpotifyAuthCallbackState();
}

class AlbumPositionPainter extends CustomPainter {
  final int totalTracks;
  final int currentTrackNo;
  double? inTrackPos;
  bool didStartYet;
  String modePlaytime;
  List<int>? playtimes;

  AlbumPositionPainter({required this.totalTracks, required this.currentTrackNo, required this.inTrackPos, required this.didStartYet, this.playtimes, required this.modePlaytime});

  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final paintTrack = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintPos = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final paintPosWait = Paint()
      ..color = Color.fromRGBO(200, 0, 0, 100)
      ..style = PaintingStyle.fill;

    double trackSize = size.width/totalTracks;
    double startSize = trackSize*currentTrackNo - trackSize;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if(modePlaytime == 'album' && playtimes != null){
      int totalTime = 0;
      int startTime = 0;
      for(int i = 0; i<playtimes!.length; i++) {
        totalTime += playtimes![i];
        if(i<currentTrackNo-1){
          startTime += playtimes![i];
        }
      }

      int trackStartTime = 0;
      for(int i = 0; i<playtimes!.length-1; i++) {
        trackStartTime += playtimes![i];
        final trackStartSize = size.width*(trackStartTime/totalTime);
        final rectAllTracks = Rect.fromLTWH(trackStartSize, 1, 1, size.height-1);
        canvas.drawRect(rectAllTracks, paintTrack);
      }

        int currentPlaytime = playtimes![currentTrackNo - 1];
        trackSize = size.width*(currentPlaytime/totalTime);
        startSize = size.width*(startTime/totalTime);
    }
    final rectTrack = Rect.fromLTWH(startSize, 1, trackSize, size.height-1);

    canvas.drawRect(rect, paint);
    canvas.drawRect(rectTrack, paintTrack);

    if(!didStartYet) {
      if (inTrackPos != null) {
        final rectPos = Rect.fromLTWH(
            startSize + trackSize * inTrackPos! - 3, -1,
            5, size.height + 3);
        canvas.drawRect(rectPos, paintPos);
      } else {
        final rectPos = Rect.fromLTWH(
            startSize - 3, -1,
            5, size.height + 3);
        canvas.drawRect(rectPos, paintPosWait);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AlbumPositionPainter oldDelegate){
    bool trackChg = oldDelegate.currentTrackNo != currentTrackNo;
    bool albmChg = oldDelegate.totalTracks != totalTracks;
    if (trackChg || albmChg){
      inTrackPos = null;
    }
    return (
        (oldDelegate.inTrackPos != inTrackPos)
            || (oldDelegate.playtimes != playtimes)
    );
  }
}

class AlbumObject extends StatefulWidget{
  AlbumObject({Key? key}) : super(key: key);

  @override
  _AlbumObjectState createState() => _AlbumObjectState();
}

class _AlbumObjectState extends State<AlbumObject>{
  String unwrapUrl = "https://thumbs.dreamstime.com/b/vinyl-record-black-isolated-white-background-31411201.jpg";
  String libraryUrl = "https://media.karousell.com/media/photos/products/2023/7/9/free__old_vinyls_and_cds_1688911333_21a3cb1e.jpg";
  String albumName = "NOT LOADED YET";
  String imageUrl = "NOT LOADED YET";
  String currentTrack = "NOT LOADED YET";
  String currentArtist = "NOT LOADED YET";
  List<String> allArtists = ["NOT LOADED YET"];
  List<String> artistsImages = [];
  String releaseDate = "2003-04-01";
  int totalTracks = 0;
  int trackNo = 0;
  int ms = 0;
  DateTime startTrackTime = DateTime.now();
  Duration pauseTime = Duration(seconds: 0);
  double partPlayed = 0;
  bool unwrap = false;
  Timer? playTimer;
  bool trackDidStartAlready = true;
  bool isPlaying = false;
  List<int>? playtimes;
  String modePlaytime = "album";
  double fontsizeSkipped = 15;
  double fontsizeAlbum = 25;
  double fontsizeTrack = 45;
  double fontsizeArtist = 40;
  double fontsizeCoArtist = 25;
  ValueNotifier<double> screenHeight = ValueNotifier<double>(0);
  bool loaded = false;
  double artistsSize = 200;

  Duration? playedMs;
  int playedTracksMs = 0;
  int playedTracks = 0;

  late Future<Uint8List> upscaledAlbumArt = _fetchAndUpscaleImage(libraryUrl, screenHeight.value.toInt() - 100, screenHeight.value.toInt() - 100);

  void initState(){
    super.initState();
    screenHeight.addListener(() async {
      loaded = false;
      await(imageUrl == "NOT LOADED YET");
      await(Duration(seconds: 1));
      upscaledAlbumArt = _fetchAndUpscaleImage(imageUrl, screenHeight.value.toInt() - 100, screenHeight.value.toInt() - 100);
    });
  }

  void updateData(
      String albumName,
      String imageUrl,
      String currentTrack,
      String currentArtist,
      List<String> allArtists,
      List<String> artistsImages,
      String releaseDate,
      int totalTracks,
      int trackNo,
      int ms,
      bool didStart,
      int playedTracks,
      bool isPlaying,
  ){
    setState(() {
      this.albumName = albumName;
      this.imageUrl = imageUrl;
      this.currentTrack = currentTrack;
      this.currentArtist = currentArtist;
      this.allArtists = allArtists;
      this.artistsImages = artistsImages;
      this.releaseDate = releaseDate;
      this.totalTracks = totalTracks;
      this.trackNo = trackNo;
      this.ms = ms;
      this.trackDidStartAlready = didStart;
      this.playedTracks = playedTracks;
      this.isPlaying = isPlaying;
    });
  }

  void startTime(DateTime startTrackTime, Duration? playedMs, int playedTracksMs){
      this.startTrackTime = startTrackTime;
      this.playedMs = playedMs;
      this.playedTracksMs = playedTracksMs;
      pauseTime = Duration(seconds: 0);
      if(playTimer != null){
        playTimer!.cancel();
      }
      playTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        DateTime currentPlayTime = DateTime.now();
        if(isPlaying) {
          Duration difference = currentPlayTime.difference(startTrackTime.add(pauseTime));
          setState(() {
            double pp = difference.inMilliseconds / ms;
            partPlayed = pp.remainder(1);
          });
        } else {
          pauseTime += Duration(seconds: 1);
        }
      });
  }

  void updateAlbumArt(String url, bool unwrap){
    setState((){
      this.unwrap = unwrap;
      upscaledAlbumArt = _fetchAndUpscaleImage(url, screenHeight.value.toInt() - 100, screenHeight.value.toInt() - 100);
    });
  }

  void updatePlaytimes(List<int>? playtimes){
    setState((){
      this.playtimes = playtimes;
    });
  }

  Future<Uint8List> _fetchAndUpscaleImage(String url, int newWidth, int newHeight) async {
    if(unwrap){
      url = unwrapUrl;
    }

    final response = await http.get(Uri.parse(url));
    if(response.statusCode == 200){
      img.Image image = img.decodeImage(response.bodyBytes)!;
      img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
      Uint8List upscaleImageBytes = Uint8List.fromList(img.encodeJpg(resized));
      loaded = true;
      return upscaleImageBytes;
    }
    else {
      throw Exception('FAILED LOADING ALBUM IMAGE');
    }
  }

  String formattedPlayedTime (Duration? d) {
    if(d == null){
      return "";
    }
    String twoDigits(int n) => n.toString().padLeft(2,'0');
    String days = d.inDays.toString();
    String daysFormatted = "";
    String twoDigitsHours = twoDigits(d.inHours.remainder(24));
    String twoDigitsMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitsSeconds = twoDigits(d.inSeconds.remainder(60));
    if(d.inDays != 0){
      daysFormatted = "$days days and ";
    }
    return "$daysFormatted$twoDigitsHours:$twoDigitsMinutes:$twoDigitsSeconds";
  }

  @override
  Widget build(BuildContext context) {
    screenHeight.value = MediaQuery.of(context).size.height;
    String formattedTrackNo = NumberFormat('00').format(trackNo);
    String formattedTotalTracks = NumberFormat('00').format(totalTracks);
    String formattedPlayTimeString = formattedPlayedTime(playedMs);
    Duration? skippedTime;

    if(playedMs != null) {
      skippedTime = Duration(milliseconds: playedTracksMs) - playedMs!;
      if(skippedTime.inSeconds <= 3){
        skippedTime = Duration(seconds: 0);
      }
    }

    String formattedSkippedTimeString = formattedPlayedTime(skippedTime);

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Spotify Album Viewer',
            style: TextStyle(
                color: Colors.white
            ),
          ),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            unwrap = !unwrap;
                            updateAlbumArt(imageUrl, unwrap);
                          });
                        },
                        child: FutureBuilder<Uint8List>(
                            future: upscaledAlbumArt,
                            builder: (context, snapshot){
                              if(!loaded){
                                return Image.network(libraryUrl, height: screenHeight.value - 100,);
                              }
                              if(snapshot.connectionState == ConnectionState.waiting){
                                return Image.network(libraryUrl, height: screenHeight.value - 100);
                              } else if(snapshot.hasError){
                                return Text("Error ${snapshot.error}");
                              } else {
                                return Image.memory(snapshot.data!);
                              }
                            }
                        )
                    ),
                    GestureDetector(
                      onTap: () {
                          if(modePlaytime == "album"){
                            setState(() {
                              modePlaytime = "track";
                            });
                          } else {
                            setState(() {
                              modePlaytime = "album";
                            });
                          }
                        },
                      child:Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                            children: [
                              CustomPaint(
                                size: Size(screenHeight.value-150, 20),
                                painter: AlbumPositionPainter(
                                  totalTracks: totalTracks,
                                  currentTrackNo: trackNo,
                                  inTrackPos: partPlayed,
                                  didStartYet: trackDidStartAlready,
                                  playtimes: playtimes,
                                  modePlaytime: modePlaytime,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "$formattedTrackNo/$formattedTotalTracks",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            ]
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 800 - artistsSize,
                        child: Column(
                          children: [
                          GestureDetector(
                            onVerticalDragUpdate: (DragUpdateDetails details) {
                              setState(() {
                                fontsizeSkipped = details.localPosition.dy;
                              });
                            },
                            child: Text(
                              "$playedTracks in $formattedPlayTimeString skipped $formattedSkippedTimeString",
                              style: TextStyle(
                                fontSize: fontsizeSkipped,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                              overflow: TextOverflow.clip,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          GestureDetector(
                            onVerticalDragUpdate: (DragUpdateDetails details) {
                              setState(() {
                                fontsizeAlbum = details.localPosition.dy;
                              });
                            },
                            child: Text(
                                "$albumName ($releaseDate):",
                                style: TextStyle(
                                  fontSize: fontsizeAlbum,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.clip,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GestureDetector(
                            onVerticalDragUpdate: (DragUpdateDetails details) {
                              setState(() {
                                fontsizeTrack = details.localPosition.dy;
                              });
                            },
                            child: Text(
                              currentTrack,
                                style: TextStyle(
                                  fontSize: fontsizeTrack,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow,
                                ),
                                overflow: TextOverflow.clip,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GestureDetector(
                              onVerticalDragUpdate: (DragUpdateDetails details) {
                                setState(() {
                                  fontsizeArtist = details.localPosition.dy;
                                });
                              },
                            child: Text(
                                "($currentArtist)",
                                style: TextStyle(
                                  fontSize: fontsizeArtist,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                                overflow: TextOverflow.clip,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                    ),
                    SizedBox(
                      width: 200,
                      height: (allArtists.length - 1)*fontsizeCoArtist,
                      child:
                      GestureDetector(
                        onVerticalDragUpdate: (DragUpdateDetails details) {
                          setState(() {
                            fontsizeCoArtist = details.localPosition.dy;
                          });
                        },
                        child: ListView.builder(
                          itemCount: allArtists.length-1,
                          itemBuilder: (context, index){
                            return Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Text(
                                allArtists[index+1],
                                style: TextStyle(
                                  fontSize: fontsizeCoArtist,
                                  color: Colors.orange,
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: TinderAuth(),
                    )
                  ],
                ),
                SizedBox(
                  width: artistsSize,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      setState( () {
                        artistsSize = 200 - details.localPosition.dx;
                      });
                    },
                    child: ListView.builder(
                      itemCount: artistsImages.length,
                      itemBuilder: (context, index){
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Image.network(
                            artistsImages[index],
                            height: (screenHeight.value - 80)/artistsImages.length,
                          ),
                        );
                      }
                    ),
                  ),
                ),
              ]
          ),
        ),
      );
    }
}

class _SpotifyAuthCallbackState extends State<SpotifyAuthCallback> {
  DateTime _currentTime = DateTime.now();
  String clientId = "";
  String clientSecret = "";
  String redirectUri = "";
  String accessToken = "";
  String refreshToken = "";
  ValueNotifier<String> _currentTrack = ValueNotifier<String>("NOT LOADED YET.");
  String _albumName = "NOT LOADED YET.";
  String _albumId = "";
  ValueNotifier<String> _albumImage = ValueNotifier<String>("");
  final List<String> _artistImages = List<String>.filled(0,'', growable: true);
  String _currentArtist = "NOT LOADED YET";
  final List<String> _artistIDs = List<String>.filled(0,'',growable: true);
  final List<String> _lastArtistIDs = List<String>.filled(0,'',growable: true);
  final List<String> _artistNames = List<String>.filled(1,'NOT LOADED YET',growable: true);
  String releaseDate = "2003-04-01";
  int totalTracks = 0;
  int trackNo = 0;
  int millisecondsOfCurrentTrack = 0;
  int millisecondsOfPlayedTracks = 0;
  int playedTracks = 0;
  bool isPlaying = false;
  Map<String,String>? headers;

  final GlobalKey<_AlbumObjectState> albumKey = GlobalKey<_AlbumObjectState>();

  @override
  void initState() {
    super.initState();

    if(widget.code != null){
      print('get Token');
        clientId = widget.clientId!;
        clientSecret = widget.clientSecret!;
        redirectUri = widget.redirectUri!;
        getSpotifyToken(widget.code!);
    } else {
      print('AUTHORIZATION NOT FOUND');
    }

    if(widget.state != null){
      print('WIDGET STATE IS NOT NULL');
    }

    Timer.periodic(Duration(seconds: 3), (Timer timer) {
      getCurrentTrack();
    });

        _currentTrack.addListener(() async{
          Duration? msPlaytime;
          playedTracks++;

          if(playedTracks == 2) {
            _currentTime = DateTime.now();
          }
          if(playedTracks >= 2){
            msPlaytime = DateTime.now().difference(_currentTime);
          }
          albumKey.currentState?.startTime(DateTime.now(), msPlaytime, millisecondsOfPlayedTracks);
          if(playedTracks >= 2){
            millisecondsOfPlayedTracks += millisecondsOfCurrentTrack;
          }

          await fetchCurrentArtistImages();
          setState(() {
          });
        });

        _albumImage.addListener(() async {
          albumKey.currentState?.updatePlaytimes(null);
          await(_albumId == "");
          List<int>playtimes = await getAlbumTrackPlaytimes(_albumId);
          albumKey.currentState?.updatePlaytimes(playtimes);
          albumKey.currentState?.updateAlbumArt(_albumImage.value, false);
        });

  }


  void getCurrentTrack() async {
    await fetchCurrentTrack();
    bool didStart = playedTracks <= 1;

    albumKey.currentState?.updateData(
        _albumName, _albumImage.value, _currentTrack.value, _currentArtist, _artistNames, _artistImages, releaseDate,
        totalTracks, trackNo, millisecondsOfCurrentTrack, didStart, playedTracks, isPlaying);
    setState(() => {
    });

  }

  Future<List<int>> getAlbumTrackPlaytimes(String albumId) async {
    final List<int> _tracks_in_ms = List<int>.filled(0,0,growable: true);
    final albumUrl = Uri.https('api.spotify.com', '/v1/albums/$albumId');
    final response = await http.get(albumUrl, headers: headers);

    if (response.statusCode == 200){
      for (int i = 0; i < totalTracks; i++){
        _tracks_in_ms.add(jsonDecode(response.body)['tracks']['items'][i]['duration_ms']);
      }
    }
    return _tracks_in_ms;
  }

  Future<void> fetchCurrentArtistImages() async{
    bool changed = false;
    _artistIDs.forEach((id) =>
      {
        if(!_lastArtistIDs.contains(id)){
          changed = true
        } else {
          _lastArtistIDs.remove(id)
        }
      }
    );
    changed = changed || !_lastArtistIDs.isEmpty;

    if(changed) {
      List<String> updatedImages = List<String>.filled(0,'',growable: true);
      print("GETT  IMMMAGGESS");
      for (int i = 0; i<_artistIDs.length; i++) {
        String artistID = _artistIDs[i];
        final artistUrl = Uri.https('api.spotify.com', '/v1/artists/$artistID');
        final response = await http.get(artistUrl, headers: headers);
        if (response.statusCode == 200) {
          updatedImages.add(jsonDecode(response.body)['images'][1]['url']);
        }
        if(i == _artistIDs.length-1){
          _artistImages.clear();
          updatedImages.forEach((url) => _artistImages.add(url));
        }
      }
    }
  }

  Future<String> fetchCurrentTrack() async {
    /* final url = Uri.https('api.spotify.com','/v1/search', {
      'q': "Nebelschlucht",
      'type': 'track',
      'limit': '1',
    }); */
    final currentlyPlayingUrl = Uri.https('api.spotify.com','/v1/me/player');

    //final responseTrack = await http.get(url, headers: headers);
    final responseCurrentlyPlaying = await http.get(currentlyPlayingUrl, headers: headers);
    //print(responseCurrentlyPlaying.body);
    if(responseCurrentlyPlaying.statusCode == 200){
      _albumName = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['name'];
      _albumImage.value = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['images'][0]['url'];
      _albumId = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['id'];
      releaseDate = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['release_date'];
      totalTracks = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['total_tracks'];
      List<dynamic> artists = jsonDecode(responseCurrentlyPlaying.body)['item']['artists'];
      _lastArtistIDs.clear();
      _artistIDs.forEach((id) => _lastArtistIDs.add(id));
      _artistIDs.clear();
      _artistNames.clear();
      artists.forEach((artistData) {
        _artistIDs.add(artistData['id']);
        _artistNames.add(artistData['name']);
      });
      _currentArtist = _artistNames[0];
      trackNo = jsonDecode(responseCurrentlyPlaying.body)['item']['track_number'];
      millisecondsOfCurrentTrack = jsonDecode(responseCurrentlyPlaying.body)['item']['duration_ms'];
      _currentTrack.value = jsonDecode(responseCurrentlyPlaying.body)['item']['name'];
      isPlaying = jsonDecode(responseCurrentlyPlaying.body)['is_playing'];

      return '200';
    }


    /*String albumId = jsonDecode(responseTrack.body)['tracks']['items'][0]['album']['id'];

    final albumUrl = Uri.https('api.spotify.com','/v1/albums/$albumId');

    final response = await http.get(albumUrl, headers: headers);
    print(response.statusCode);
    print(response.body);
    if(response.statusCode == 200){
      _albumName = jsonDecode(response.body)['name'];
      String? imageUrl = jsonDecode(response.body)['images'][0]['url'];
      if(imageUrl != null){
        _albumImage = imageUrl;
      }

      return cT;
    }*/


    return responseCurrentlyPlaying.statusCode.toString();
  }

  Future<void> getSpotifyToken(String code) async {
    final url = Uri.https('accounts.spotify.com', '/api/token');

    final headers = {
        'content-type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ${base64Encode(
            utf8.encode('$clientId:$clientSecret'))}',
    };
    final body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'http://localhost:8888/callback',
    };

    final encodedBody = body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await http.post(
        url, headers: headers, body: encodedBody);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final newAccessToken = body['access_token'];
      final newRefreshToken = body['refresh_token'];
      refreshToken = newRefreshToken;
      accessToken = newAccessToken;

      this.headers = {
        'Authorization': 'Bearer $accessToken',
      };

      int _start = body['expires_in'];
      DateTime nxt = DateTime.now().add(Duration(seconds: _start));
      print('nextRefreshing at $nxt');
      Timer(Duration(seconds: _start),() {
        getSpotifyRefreshToken(clientId, clientSecret, refreshToken);
      });
    } else {
      print(response.body);
    }
  }

  Future<void> getSpotifyRefreshToken(String clientId, String clientSecret,
      String refreshToken) async {
    final url = Uri.https('accounts.spotify.com', '/api/token');

    final headers = {
      'content-type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ${base64Encode(
          utf8.encode('$clientId:$clientSecret'))}',
    };
    final body = {
      'grant_type': 'refresh_token',
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };

    final encodedBody = body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');

    print("REFRESHING");
    final response = await http.post(
        url, headers: headers, body: encodedBody);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final newAccessToken = body['access_token'];
      print('refreshed access token $newAccessToken');
      accessToken = newAccessToken;

      this.headers = {
        'Authorization': 'Bearer $accessToken',
      };

      int _start = body['expires_in'];
      DateTime nxt = DateTime.now().add(Duration(seconds: _start));
      print('nextRefreshing at $nxt');
      Timer(Duration(seconds: _start),(){
          getSpotifyRefreshToken(clientId,clientSecret,refreshToken);
      });
    } else {
      print(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AlbumObject(key: albumKey)
      ),
    );
  }
}


