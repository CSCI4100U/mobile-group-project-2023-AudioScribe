import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> createNewDirectory(String directoryName, String title) async {
  // Get the external storage directory
  Directory? externalDirectory = await getExternalStorageDirectory();
  String? externalPath = externalDirectory?.path;

  // Create a new directory with no spaces
  String directoryPath =
      "$externalPath/$directoryName/$title".replaceAll(' ', '_');
  Directory newDirectory = Directory(directoryPath);

  if (!await newDirectory.exists()) {
    await newDirectory.create(
        recursive: true); // Create the directory if it doesn't exist
  }

  return directoryPath;
}