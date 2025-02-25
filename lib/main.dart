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

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Album Viewer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      ),
      onGenerateRoute: _onGenerateRoute,
    );
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
}

class SpotifyAuth extends StatefulWidget {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;

  SpotifyAuth({this.clientId, this.clientSecret, this.redirectUri});

  @override
  _SpotifyAuthState createState() => _SpotifyAuthState();
}

class _SpotifyAuthState extends State<SpotifyAuth> {
  String? clientId = "";
  String? clientSecret = "";
  String? redirectUri = "";

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
    clientId = widget.clientId;
    clientSecret = widget.clientSecret;
    redirectUri = widget.redirectUri;
  }

  Future<void> login() async {
    final state = generateRandomString(16);
    final scope = 'user-read-currently-playing';
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'scope': scope,
      'redirect_uri': redirectUri,
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

  AlbumPositionPainter({required this.totalTracks, required this.currentTrackNo});

  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final paintTrack = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    double trackSize = size.width/totalTracks;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rectTrack = Rect.fromLTWH(trackSize*currentTrackNo - trackSize, 1, trackSize, size.height-1);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rectTrack, paintTrack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate){
    return false;
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
  bool unwrap = false;
  late Future<Uint8List> upscaledAlbumArt = _fetchAndUpscaleImage(libraryUrl, getScreenHeight() - 100, getScreenHeight() - 100);

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
    });
  }

  void updateAlbumArt(String url){
    setState((){
      upscaledAlbumArt = _fetchAndUpscaleImage(url, getScreenHeight() - 100, getScreenHeight() - 100);
    });
  }

  int getScreenHeight() {
    double doubleValue = WidgetsBinding.instance.window.physicalSize.height /
        WidgetsBinding.instance.window.devicePixelRatio;
    return doubleValue.toInt();
  }

  Future<Uint8List> _fetchAndUpscaleImage(String url, int newWidth, int newHeight) async {
    final response = await http.get(Uri.parse(url));
    if(response.statusCode == 200){
      img.Image image = img.decodeImage(response.bodyBytes)!;
      img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
      Uint8List upscaleImageBytes = Uint8List.fromList(img.encodeJpg(resized));
      return upscaleImageBytes;
    }
    else {
      throw Exception('FAILED LOADING ALBUM IMAGE');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height - 50;
    double screenwidth = MediaQuery.of(context).size.width;
    String formattedTrackNo = NumberFormat('00').format(trackNo);
    String formattedTotalTracks = NumberFormat('00').format(totalTracks);

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
                      updateAlbumArt(unwrap?unwrapUrl:imageUrl);
                    });
                  },
                  child: FutureBuilder<Uint8List>(
                      future: upscaledAlbumArt, 
                      builder: (context, snapshot){
                        if(snapshot.connectionState == ConnectionState.waiting){
                          return Image.network(libraryUrl, height: screenheight - 50);
                        } else if(snapshot.hasError){
                          return Text("Error ${snapshot.error}");
                        } else {
                          return Image.memory(snapshot.data!);
                        }
                      }
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                       CustomPaint(
                         size: Size(550, 20),
                         painter: AlbumPositionPainter(
                           totalTracks: totalTracks,
                           currentTrackNo: trackNo,
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
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 400,
                  child: Column(
                      children: [
                        Text(
                            "$albumName ($releaseDate):",
                            style: TextStyle(
                              fontSize: 25.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.center,
                        ),
                        Text(
                          currentTrack,
                          style: TextStyle(
                            fontSize: 45.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "($currentArtist)",
                          style: TextStyle(
                            fontSize: 42.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                         overflow: TextOverflow.clip,
                         textAlign: TextAlign.center,
                        ),
                      ],
                    )
                ),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: ListView.builder(
                      itemCount: allArtists.length-1,
                      itemBuilder: (context, index){
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Text(
                            allArtists[index+1],
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.orange,
                            ),
                          ),
                        );
                      }
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 300,
              child: ListView.builder(
                    itemCount: artistsImages.length,
                    itemBuilder: (context, index){
                      return Padding(
                       padding: const EdgeInsets.all(1.0),
                       child: Image.network(
                         artistsImages[index],
                         height: screenheight/artistsImages.length,
                       ),
                      );
                    }
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
  ValueNotifier<String> _albumImage = ValueNotifier<String>("");
  final List<String> _artistImages = List<String>.filled(0,'', growable: true);
  String _currentArtist = "NOT LOADED YET";
  final List<String> _artistIDs = List<String>.filled(0,'',growable: true);
  final List<String> _lastArtistIDs = List<String>.filled(0,'',growable: true);
  final List<String> _artistNames = List<String>.filled(1,'NOT LOADED YET',growable: true);
  String releaseDate = "2003-04-01";
  int totalTracks = 0;
  int trackNo = 0;

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
          await fetchCurrentArtistImages();
          setState(() {
          });
        });

        _albumImage.addListener(() {
          albumKey.currentState?.updateAlbumArt(_albumImage.value);
        });

  }

  void getCurrentTrack() async {
    await fetchCurrentTrack();
    albumKey.currentState?.updateData(
        _albumName, _albumImage.value, _currentTrack.value, _currentArtist, _artistNames, _artistImages, releaseDate, totalTracks, trackNo);
    setState(() => {
    });

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
      final headers = {
        'Authorization': 'Bearer $accessToken',
      };

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
    final currentlyPlayingUrl = Uri.https('api.spotify.com','/v1/me/player/currently-playing');

    final headers = {
      'Authorization': 'Bearer $accessToken',
    };
    //final responseTrack = await http.get(url, headers: headers);
    final responseCurrentlyPlaying = await http.get(currentlyPlayingUrl, headers: headers);
    //print(responseCurrentlyPlaying.body);
    if(responseCurrentlyPlaying.statusCode == 200){
      _albumName = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['name'];
      _albumImage.value = jsonDecode(responseCurrentlyPlaying.body)['item']['album']['images'][0]['url'];
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
      _currentTrack.value = jsonDecode(responseCurrentlyPlaying.body)['item']['name'];

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
      print(response.body);

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


