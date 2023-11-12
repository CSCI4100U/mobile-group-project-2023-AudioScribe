import 'package:audioscribe/components/app_header.dart';
import 'package:audioscribe/components/book_grid.dart';
import 'package:audioscribe/components/search_bar.dart';
import 'package:audioscribe/utils/database/book_model.dart';
import 'package:audioscribe/utils/database/user_model.dart';
import 'package:audioscribe/data_classes/user.dart' as userClient;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class CollectionPage extends StatefulWidget {
	const CollectionPage({Key? key}): super(key: key);

	@override
	_CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {

	List<Map<String, dynamic>> userBooks = [];

	@override
	void initState() {
		super.initState();
		fetchUserBooks();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF303030),
			body: _buildCollectionPage(context)
		);
	}

	Widget _buildCollectionPage(BuildContext context) {
		return Stack(
			children: [
				SafeArea(
					child: Column(
						children: [
							// Search bar
							const AppSearchBar(hintText: "search for your favourite books"),

							// Book grid
							Expanded(child: BookGridView(books: userBooks)),
						],
					)
				)
			],
		);
	}

	/// get the current instance of the user that is logged In
	String getCurrentUserId() {
		User? currentUser = FirebaseAuth.instance.currentUser;
		if (currentUser != null) {
			String uid = currentUser.uid;
			return uid;
		} else {
			return 'No user is currently signed in';
		}
	}

	/// function to fetch users books
	Future<void> fetchUserBooks() async {
		try {
			// get current user instance
			String userId = getCurrentUserId();
			UserModel userModel = UserModel();

			// get user id
			userClient.User? user = await userModel.getUserByID(userId);
			// print('user id: $user');

			// if the user exists
			if (user != null) {
				var books = await userModel.getAllUserBooks(userId);
				print('collection_page (78) books: $books');

				// convert books to book row format
				setState(() {
					userBooks = books.map((book) => {
						'id': book['bookId'],
						'image': book['imageFileLocation'] as String? ?? '',
						'title': book['title'] as String? ?? '',
						'author': book['author'] as String? ?? '',
						'summary': book['textFileLocation'] as String? ?? ''
					}).toList();
				});
			}
		} catch (e) {
			print("Error fetching user books: $e");
		}
	}
}