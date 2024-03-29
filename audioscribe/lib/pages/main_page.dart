import 'package:audioscribe/app_constants.dart';
import 'package:audioscribe/pages/uploadBook_page.dart';
import 'package:audioscribe/utils/file_ops/make_directory.dart';
import 'package:audioscribe/utils/interface/custom_route.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:audioscribe/components/popup_circular_button.dart';
import 'package:audioscribe/pages/collection_page.dart';
import 'package:audioscribe/pages/home_page.dart';
import 'package:audioscribe/pages/settings_page.dart';
import 'package:audioscribe/components/camera_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/file_ops/file_to_txt_converter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int homePageKey = 0;

  void refreshHomePage() {
    setState(() {
      homePageKey++;
    });
  }

  // list of widgets
  List<Widget> get _widgetOptions => [
        HomePage(key: ValueKey('HomePage$homePageKey')),
        const CollectionPage(key: ValueKey('CollectionPage')),
        const SettingsPage(key: ValueKey('SettingsPage'))
      ];

  /// Used to navigate to different screens/pages
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // sign user out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  String currentPageHeaderTitle() {
    String? currentUser =
        FirebaseAuth.instance.currentUser?.email?.split('@')[0];
    switch (_selectedIndex) {
      case 0:
        return '${currentUser?[0].toUpperCase()}${currentUser?.substring(1).toLowerCase()}';
      case 1:
        return 'Your collection';
      case 2:
        return 'Settings';
      default:
        return 'AudioScribe';
    }
  }

  Future showModalOptions() {
    return showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
                color: Color(0xFF242424),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                )),
            child: SizedBox(
                height: 200,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // upload button
                      PopUpCircularButton(
                          buttonIcon: const Icon(Icons.file_upload,
                              color: Colors.white, size: 35.0),
                          onTap: _uploadBook,
                          label: 'Upload'),

                      // horizontal spacing
                      const SizedBox(width: 60.0),

                      // camera button
                      PopUpCircularButton(
                          buttonIcon: const Icon(Icons.camera,
                              color: Colors.white, size: 35.0),
                          onTap: () => _navigateToCameraScreen(context),
                          label: 'Camera'),
                    ])),
          );
        });
  }

  Future<void> _uploadBook() async {
    // Use FilePicker to let the user select a text file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'mp3'],
    );

    if (result != null) {
      // Get the selected file
      PlatformFile file = result.files.first;
      String fileContent = '';

      // handle text files
      if (path.extension(file.path!) == ".txt") {
        fileContent = await File(file.path!).readAsString();

        // handle pdf files
      } else if (path.extension(file.path!) == '.pdf') {
        String bookDirectoryPath =
            await createNewDirectoryNoTitle("AudioScribeTextBooks");

        String fileName = path.basenameWithoutExtension(file.name);
        await convertFileToTxt(file.path!, bookDirectoryPath);
        fileContent =
            await File('$bookDirectoryPath/$fileName.txt').readAsString();

        // handle mp3 files
      } else if (path.extension(file.path!) == '.mp3') {
        fileContent = file.path!;
      }

      // Go to upload page
      if (mounted) _navigateToUploadBookPage(context, fileContent);
    } else {
      // User canceled the picker
      print("No file selected");
    }
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CameraScreen(),
    ));
  }

  void _navigateToUploadBookPage(BuildContext context, String text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadBookPage(
            text: text,
            onUpload: () {
              print("new book got uploaded");
              refreshHomePage();
            }),
      ),
    ).then((value) {
      print("back to main page");
      setState(() {
        _selectedIndex = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AudioScribe'),
        backgroundColor: AppColors.primaryAppColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'logout') {
                  // perform logout
                  signOut();
                } else if (value == 'setting') {
                  // navigate to settings page
                  Navigator.of(context).push(
                      CustomRoute.routeTransitionBottom(const SettingsPage()));
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'setting',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white),
                      SizedBox(width: 10.0),
                      Text('Settings', style: TextStyle(color: Colors.white))
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 10.0),
                      Text('Logout', style: TextStyle(color: Colors.white))
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.account_circle,
                  size: 42.0, color: Colors.white),
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xFF303030),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _widgetOptions.elementAt(_selectedIndex),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: _buildBottomActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF524178),
      onPressed: showModalOptions,
      child: const Icon(Icons.add, size: 35.0),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      height: 40.0,
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(),
          IconButton(
              onPressed: () => _onItemTapped(0),
              icon: Icon(Icons.home,
                  size: 30.0,
                  color: _selectedIndex == 0
                      ? const Color(0xFF9260FC)
                      : Colors.white)),
          const Spacer(),
          const Spacer(),
          const SizedBox(width: 48),
          IconButton(
            onPressed: () => _onItemTapped(1),
            icon: Icon(Icons.bookmark,
                size: 30.0,
                color: _selectedIndex == 1
                    ? const Color(0xFF9260FC)
                    : Colors.white),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
