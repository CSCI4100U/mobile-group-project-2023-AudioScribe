import "package:audioscribe/app_constants.dart";
import "package:audioscribe/components/PrimaryAppButton.dart";
import "package:audioscribe/components/image_container.dart";
import "package:audioscribe/data_classes/librivox_book.dart";
import "package:audioscribe/pages/audio_page.dart";
import "package:audioscribe/services/internet_archive_service.dart";
import "package:audioscribe/utils/database/book_model.dart";
import "package:audioscribe/utils/database/cloud_storage_manager.dart";
import "package:audioscribe/utils/interface/custom_route.dart";
import "package:audioscribe/utils/interface/snack_bar.dart";
import "package:flutter/material.dart";
import 'package:audioscribe/data_classes/bookmark.dart';
import 'package:audioscribe/data_classes/favourite.dart';

class DetailsPage extends StatefulWidget {
	final LibrivoxBook book;
	final VoidCallback? onChange;
	final String? audioBookPath;

	const DetailsPage({
		super.key,
		required this.book,
		this.onChange,
		this.audioBookPath
	});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
	late bool isBookFavourited = widget.book.isFavourite == 1 ? true : false;
	late bool isBookBookmarked = widget.book.isBookmark == 1 ? true : false;
	late Bookmark bookmarkManager = Bookmark(bookTitle: widget.book.title, bookAuthor: widget.book.author);
	late Favourite favouriteManager = Favourite(bookId: widget.book.id);

	@override
	void initState() {
		super.initState();
		print('status: $isBookBookmarked, ${widget.book.isBookmark}, ${widget.book.bookType}');
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.backgroundColor1,
			appBar: AppBar(
				title: Text(widget.book.title),
				backgroundColor: AppColors.primaryAppColor,
			),
			body: _buildBookDetails(context),
		);
	}

	/// handle bookmark click
	void handleBookmark() async {
		bool isBookmarked = isBookBookmarked
		? await bookmarkManager.removeBookmark(widget.book.id)
		: await bookmarkManager.addBookmark(widget.book.id);

		if (isBookmarked) {
			setState(() {
			  	isBookBookmarked = !isBookBookmarked;
			});
			print('Bookmark status changed: $isBookBookmarked');
		} else {
			errorSnackbar("Failed to change bookmark status");
			print('Failed to change bookmark status.');
		}
		widget.onChange!();
	}

	/// handle favourite click
	void handleFavourite() async {
		bool isFavourited = isBookFavourited
		? await favouriteManager.unFavouriteBook(widget.book.id)
		: await favouriteManager.favouriteBook(widget.book.id);

		if (isFavourited) {
			setState(() {
			  	isBookFavourited = !isBookFavourited;
			});
			print("Favourite status change: $isBookFavourited");
		} else {
			errorSnackbar("Failed to change favourite status");
			print("Failed to change favourite status");
		}
		widget.onChange!();
	}

	/// handles deleting an uploaded item
	void handleDelete() async {
		// show confirmation dialog
		bool confirm = await showDialog(
			context: context,
			builder: (BuildContext context) {
				return AlertDialog(
					title: const Text("Confirm Delete"),
					content: Text("Are you sure you want delete ${widget.book.title}?"),
					actions: [
						TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
						TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete"))
					]
				);
			}
		) ?? false;

		if (confirm) {
			await deleteUserBook(getCurrentUserId(), widget.book.id);
			await BookModel().deleteBookWithId(widget.book.id);

			if (widget.onChange != null) {
			  widget.onChange!();
			} else {
			  errorSnackbar("Error deleting item");
			}

			print("Deleting item ${widget.book.id}, ${widget.book.title}");

			if (mounted) Navigator.of(context).pop();
		}
	}

	/// snackbar for error occurrence used on various click events
	void errorSnackbar(String message) {
		SnackbarUtil.showSnackbarMessage(context, message, Colors.white);
	}

	/// fetch data for chapters
	Future<List<Map<String, String>>?> fetchChapters(String identifier) async {
		// perform fetch
		if (identifier.isNotEmpty) {
			ArchiveApiProvider archiveApiProvider = ArchiveApiProvider();

			// fetch audio files list
			List<Map<String, String>> audioFilesList = await archiveApiProvider.fetchAudioFiles(identifier);

			return audioFilesList;
		} else {
			return null;
		}
	}

	Widget _buildBookDetails(BuildContext context) {
		return Stack(
			children: [
				SafeArea(
					child: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.center,
								children: [
									// book image //
									Center(
										child: ImageContainer(imagePath: widget.book.imageFileLocation, bookType: widget.book.bookType, size: 72.0)
									),

									// book title //
									const SizedBox(height: 15.0),
									Text(widget.book.title, style: const TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w500)),

									// book author //
									const SizedBox(height: 10.0),
									Text(widget.book.author, style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w400)),

									// Listen button //
									const SizedBox(height: 10.0),
									PrimaryAppButton(buttonText: 'Listen', buttonSize: 0.85, onTap: () {
										// get audio book path
										if (widget.audioBookPath != null) {
											String audioPath = widget.audioBookPath as String;
											Navigator.of(context).push(CustomRoute.routeTransitionBottom(
												AudioPlayerPage(
													bookId: widget.book.id,
													imagePath: widget.book.imageFileLocation,
													bookTitle: widget.book.title,
													bookAuthor: widget.book.author,
													isBookmarked: widget.book.isBookmark == 1 ? true : false,
													audioBookPath: audioPath,
													onBookmarkChanged: (bool isBookmarked) {
														setState(() {
														  	isBookBookmarked = isBookmarked;
														});
													}
												)
											));
										}
									}),

									// Icons (bookmark, delete, favourite) //
									buildIcons(),

									// summary //
									const SizedBox(height: 10.0),
									const Align(alignment: Alignment.centerLeft,
										child: Text('Summary', textAlign: TextAlign.left, style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w500))
									),
									const SizedBox(height: 10.0),
									buildSummaryContainer(widget.book.description),

									// Chapters //
									const SizedBox(height: 10.0),
									buildChapterList(widget.book.identifier)
								],
							),
						),
					)
				)
			]	
		);
	}

	// build icons row
	Widget buildIcons() {
		return Row(
			children: [
				// delete icon
				widget.book.bookType == 'UPLOAD' ?
				IconButton(
					onPressed: handleDelete,
					icon: const Icon(Icons.delete_forever_outlined, color: Colors.white, size: 42.0)
				) : Container(),
				const Spacer(),
				// Bookmark icon
				IconButton(
					onPressed: handleBookmark,
					icon: isBookBookmarked
					? const Icon(Icons.bookmark_add, color: Colors.white, size: 42.0)
					: const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 42.0),
				),
				// favourite icon
				IconButton(
					onPressed: handleFavourite,
					icon: isBookFavourited
					? const Icon(Icons.favorite, color: Colors.red, size: 42.0)
					: const Icon(Icons.favorite_border, color: Colors.white, size: 42.0)
				)
			],
		);
	}

	// build summary container
	Widget buildSummaryContainer(String summary) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
			decoration: BoxDecoration(
				color: AppColors.secondaryAppColor,
				borderRadius: BorderRadius.circular(15.0),
			),
			height: MediaQuery.of(context).size.width * 0.3,
			child: SingleChildScrollView(
				child: Align(
					alignment: Alignment.centerLeft,
					child: Padding(
						padding: const EdgeInsets.symmetric(vertical: 10.0),
						child: Text(summary, style: const TextStyle(color: Colors.white, fontSize: 16.0, height: 1.5))
					)
				),
			)
		);
	}

	// build chapter container
	Widget buildChapterList(String identifier) {
		return FutureBuilder(
			future: fetchChapters(identifier),
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.waiting) {
					return const CircularProgressIndicator();
				} else if (snapshot.hasError) {
					errorSnackbar("Error: ${snapshot.error}");
					return Container();
				} else if (snapshot.hasData) {
					return Column(
						children: [
							// Chapter Title //
							const Align(
								alignment: Alignment.centerLeft,
								child: Text('Chapters', style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w500)),
							),
							const SizedBox(height: 10.0),
							// Chapter list //
							ListView.builder(
								shrinkWrap: true,
								itemCount: snapshot.data?.length,
								itemBuilder: (context, index) {
									var data = snapshot.data?[index];
									return GestureDetector(
										onTap: () => print('${data}'),
										child: Padding(
											padding: const EdgeInsets.all(2.0),
											child: Container(
												decoration: const BoxDecoration(
													color: AppColors.secondaryAppColor
												),
												child: Row(
													children: [
														const Padding(
															padding: EdgeInsets.all(4.0),
															child: Icon(Icons.play_circle_fill, color: Colors.white),
														),
														Flexible(
															child: Padding(
																padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 5.0),
																child: Text(data!['chapter']!, style: TextStyle(color: Colors.white, fontSize: 18.0)),
															),
														)
													],
												)
											),
										)
									);
								}
							)
						],
					);
				}
				return Container();
			}
		);
	}
}