import 'package:flutter/material.dart';


class RestaurantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RestaurantPage(),
    );
  }
}

class RestaurantPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Builder(
          builder: (context) {

            //I would like to figure out how to change the drawer size
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
              Scaffold.of(context).openDrawer();
              },
            );
          },        
        ),
}