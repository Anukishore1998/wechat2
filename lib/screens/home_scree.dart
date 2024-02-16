import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/widget/chat_user_card.dart';

import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import 'profile_screen.dart';

//home screen -- where all available contacts are shown
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];

  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if search is on & back button is pressed then close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          //app bar
          appBar: AppBar(
            flexibleSpace: _appBar(),
            // leading: const Icon(CupertinoIcons.home),
            // title: _isSearching
            //     ? TextField(
            //         decoration: const InputDecoration(
            //             border: InputBorder.none, hintText: 'Name, Email, ...'),
            //         autofocus: true,
            //         style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
            //         //when search text changes then updated search list
            //         onChanged: (val) {
            //           //search logic
            //           _searchList.clear();
            //           for (var i in _list) {
            //             if (i.name.toLowerCase().contains(val.toLowerCase()) ||
            //                 i.email.toLowerCase().contains(val.toLowerCase())) {
            //               _searchList.add(i);
            //               setState(() {
            //                 _searchList;
            //               });
            //             }
            //           }
            //         },
            //       )
            //     : const Text('CHATAPP'),
            actions: [
              //search user button
              // IconButton(
              //     onPressed: () {
              //       setState(() {
              //         _isSearching = !_isSearching;
              //       });
              //     },
              //     icon: Icon(_isSearching
              //         ? CupertinoIcons.clear_circled_solid
              //         : Icons.search)),
              //more features button
              IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.notifications,
                    size: 30,
                    color: Colors.white,
                  )),
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(user: APIs.me)));
                },
                icon: Image.asset(
                  'assets/images/manview.png',
                  height: 160,
                ),
              )
            ],
          ),
          // appBar: AppBar(
          //   backgroundColor: Color.fromRGBO(4, 27, 90, 1),
          //   leading: Icon(
          //     Icons.arrow_back,
          //     color: Colors.white,
          //   ),
          //   actions: [
          //     Padding(
          //       padding: const EdgeInsets.only(right: 15.0),
          //       child: Icon(
          //         Icons.account_balance_wallet_outlined,
          //         size: 27,
          //         color: Colors.white,
          //       ),
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.only(right: 20.0),
          //       child: Icon(
          //         Icons.notification_add,
          //         color: Colors.white,
          //         size: 27,
          //       ),
          //     )
          //   ],
          //   toolbarHeight: 70,
          // ),

          //floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
                backgroundColor: Color.fromARGB(255, 92, 156, 94),
                onPressed: () {
                  _addChatUserDialog();
                },
                child: const Icon(
                  Icons.add_card_outlined,
                  color: Colors.white,
                )),
          ),

          //body
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return const Center(
                        //     child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchList.length
                                    : _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                      user: _isSearching
                                          ? _searchList[index]
                                          : _list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  // for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: Row(
                children: const [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text('  Add User')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'Email Id',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.blue, fontSize: 16))),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}

Widget _appBar() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color.fromRGBO(9, 29, 97, 1), Color.fromRGBO(8, 27, 85, 1)],
      ),
    ),
  );
}
