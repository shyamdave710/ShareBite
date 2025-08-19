import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold(
      {
        required this.title,
        required this.backgroundColor,
        required this.child,
        this.drawer,
        this.bottomTabs,
        this.bottomNav,
        super.key
      });

  final Widget child;
  final String title;
  final Color backgroundColor;
  final Drawer? drawer;
  final TabBar? bottomTabs;
  final BottomNavigationBar? bottomNav;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: drawer,
      appBar: AppBar(
        actionsIconTheme: const IconThemeData(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style:const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 10,
        shadowColor: const Color.fromRGBO(11, 61, 9, 1.0),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50))),
        backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
        bottom: bottomTabs,
      ),
      bottomNavigationBar: bottomNav,
      body: child,
    );
  }
}
