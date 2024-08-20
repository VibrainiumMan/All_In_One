import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Home Page",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: ListView(
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.inversePrimary
                    )
                ),
                margin: EdgeInsets.all(10),
                width: 400, height: 150,
                child: Center(
                  child: Text("Add ToDo List"),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.inversePrimary
                    )
                ),
                margin: EdgeInsets.all(10),
                width: 400, height: 200,
                child: Center(
                  child: Text("Add Schedule"),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.inversePrimary
                    )
                ),
                margin: EdgeInsets.all(10),
                width: 400, height: 400,
                child: Center(
                  child: Text("Calendar Here"),
                ),
              ),
            ]
        ),
      ),

    );
  }
}
