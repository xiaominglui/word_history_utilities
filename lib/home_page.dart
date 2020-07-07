import 'package:flutter/material.dart';
import 'package:word_history_utilities/fragments/options_fragment.dart';
import 'package:word_history_utilities/fragments/word_history_fragment.dart';

import 'i18n/i18n_minimal.dart';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int _selectedDrawerIndex = 0;

  final GlobalKey<WordHistoryFragmentState> _wordHistoryFragmentState =
      GlobalKey<WordHistoryFragmentState>();

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
              if (_wordHistoryFragmentState.currentState != null &&
                  _wordHistoryFragmentState.currentState.deleting != null &&
                  !_wordHistoryFragmentState.currentState.deleting) {
                _startRefresh();
              } else {
                print('in deleting, can NOT sync');
              }
            },
          )
        ];
      case 1:
        return [];
      default:
        return [];
    }
  }

  void _startRefresh() {
    _wordHistoryFragmentState.currentState.refresh(true);
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> drawerOptions = [];
    final drawerItems = [
      new DrawerItem(
          MinimalLocalizations.of(context).wordHistoryMenu, Icons.map),
      new DrawerItem(MinimalLocalizations.of(context).optionsMenu, Icons.star),
      new DrawerItem(MinimalLocalizations.of(context).privacyMenu, Icons.lock),
      new DrawerItem(MinimalLocalizations.of(context).helpMenu, Icons.help)
    ];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
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
        title: new Text(drawerItems[_selectedDrawerIndex].title),
        actions: _getAppbarActions(_selectedDrawerIndex),
      ),
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: Text(MinimalLocalizations.of(context).appTitle),
                accountEmail: null),
            new Column(children: drawerOptions)
          ],
        ),
      ),
      body: _getDrawerItemWidget(_selectedDrawerIndex),
    );
  }
}
