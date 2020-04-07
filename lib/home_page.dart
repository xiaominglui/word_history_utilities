import 'package:flutter/material.dart';
import 'package:word_history_utilities/fragments/options_fragment.dart';
import 'package:word_history_utilities/fragments/word_history_fragment.dart';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class HomePage extends StatefulWidget {
  final drawerItems = [
    new DrawerItem("Word History", Icons.map),
    new DrawerItem("Options", Icons.star),
    new DrawerItem("Iniciar Sesion", Icons.lock)
  ];

  @override
  State<StatefulWidget> createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int _selectedDrawerIndex = 0;

  final GlobalKey<WordHistoryFragmentState> _wordHistoryFragmentState = GlobalKey<WordHistoryFragmentState>();

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new WordHistoryFragment(key: _wordHistoryFragmentState);
      case 1:
        return new OptionsFragment();
      default:
        return new Text("Error");
    }
  }

  _getAppbarActions(int pos) {
    switch (pos) {
      case 0:
        return [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync history words',
            onPressed: () {
              _wordHistoryFragmentState.currentState.fetchHistoryWords();
            },
          )
        ];
      case 1:
        return [];
      default:
        return [];
    }
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> drawerOptions = [];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: new Icon(d.icon),
        title: new Text(d.title),
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    return new Scaffold(
      appBar: new AppBar(
        // here we display the title corresponding to the fragment
        // you can instead choose to have a static title
        title: new Text(widget.drawerItems[_selectedDrawerIndex].title),
        actions: _getAppbarActions(_selectedDrawerIndex),
      ),
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: new Text("TURISMO BOLIVIA"), accountEmail: null),
            new Column(children: drawerOptions)
          ],
        ),
      ),
      body: _getDrawerItemWidget(_selectedDrawerIndex),
    );
  }
}
