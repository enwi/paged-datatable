import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:paged_datatable_example/post.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: PagedDataTable<String, Post>(
        fetchPage: (pageToken, pageSize, sortBy) async {
          var result = await PostsRepository.getPosts(
            pageSize: pageSize, 
            pageToken: pageToken,
            sortBy: sortBy?.columnId,
            sortDescending: sortBy?.descending ?? false
          );
          return PaginationResult.items(elements: result.items, nextPageToken: result.nextPageToken);
        },
        initialPage: "",
        columns: [
          TableColumn(
            title: "Identificator", 
            itemBuilder: (item) => Text(item.id.toString()),
            sizeFactor: .05
          ),
          TableColumn(
            title: "Author", 
            itemBuilder: (item) => Text(item.author)
          ),
          TableColumn(
            title: "Content", 
            itemBuilder: (item) => Tooltip(
              message: item.content,
              child: Text(item.content),
            ),
            sizeFactor: .3
          ),
          TableColumn(
            id: "createdAt",
            title: "Created At", 
            sortable: true,
            itemBuilder: (item) => Text(DateFormat.yMd().format(item.createdAt))
          ),
          TableColumn(
            title: "Gender", 
            itemBuilder: (item) => Text(item.authorGender.name)
          ),
          TableColumn(
            title: "Enabled", 
            itemBuilder: (item) => Text(item.isEnabled ? "Yes" : "No")
          ),
          TableColumn(
            title: "Number", 
            id: "number",
            sortable: true,
            sizeFactor: .05,
            isNumeric: true,
            itemBuilder: (item) => Text(item.number.toString())
          ),
          TableColumn(
            title: "Fixed Value", 
            itemBuilder: (item) => const Text("abc")
          ),
        ],
      ),
    );
  }
}