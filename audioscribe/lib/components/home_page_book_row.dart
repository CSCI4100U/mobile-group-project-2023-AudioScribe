import 'package:flutter/material.dart';

class BookRow extends StatefulWidget {
	final List<Map<String, dynamic>> books;
	final Function(int index, String title, String author, String image, String summary) onBookSelected;

	const BookRow({
		super.key,
		required this.books,
		required this.onBookSelected
	});

	@override
	_BookRow createState() => _BookRow();
}

class _BookRow extends State<BookRow> {

	@override
	Widget build(BuildContext context) {
		// use media query to get width of screen (used for responsive height)
		var screenWidth = MediaQuery.of(context).size.width;

		var bookWidth = screenWidth / 3;
		var bookHeight = bookWidth / 0.8;

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
			height: bookHeight + 50,//200,
			child: ListView.builder(
				scrollDirection: Axis.horizontal,
				itemCount: widget.books.length,
				itemBuilder: (context, index) {
					return GestureDetector(
						onTap: () {
							// print("selected book = ${widget.books[index]['title']!}");
							var selectedBook = widget.books[index];
							// print("selected book = $selectedBook");
							widget.onBookSelected(
								selectedBook['id']!,
								selectedBook['title']!,
								selectedBook['author']!,
								selectedBook['image']!,
								selectedBook['summary']!
							);
						},
						child: Container(
							width: 120,
							padding: const EdgeInsets.all(8.0),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									AspectRatio(
										aspectRatio: 0.7,
										child: Container(
											decoration: BoxDecoration(
												color: Colors.white,
												borderRadius: BorderRadius.circular(4),
												boxShadow: [
													BoxShadow(
														color: Colors.black.withOpacity(0.2),
														blurRadius: 3,
														offset: const Offset(0, 2),
													),
												],
												image: DecorationImage(
													image: AssetImage(widget.books[index]['image']!),
													fit: BoxFit.fill
												),
											),
										),
									),
									const SizedBox(height: 8),

									Text(
										widget.books[index]['title']!,
										textAlign: TextAlign.center,
										style: const TextStyle(
											color: Colors.white,
											fontSize: 10,
											fontWeight: FontWeight.w500
										),
										maxLines: 2,
										overflow: TextOverflow.ellipsis,
									)
								],
							)
						),
					);
				}
			),
		);
	}
}