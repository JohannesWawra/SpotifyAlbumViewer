import 'package:flutter/cupertino.dart';

class AlbumPainterWidget extends StatelessWidget{
  final DateTime currentTime;
  final String currentTrack;

  AlbumPainterWidget({required this.currentTime, required this.currentTrack});

  @override
  Widget build(BuildContext context){
    return Container(
      width: 300,
      height: 300,
      child: Text("It is $currentTime and current Track is $currentTrack"),
    );
  }
}