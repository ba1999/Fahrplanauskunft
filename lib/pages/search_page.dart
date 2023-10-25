// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  // Constructor for the SearchPage widget
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller for the search input field
  TextEditingController searchController = TextEditingController();

  // List to store search results
  List<Map<String, dynamic>> searchResults = [];

  // Timer for debouncing the search input
  Timer? _debounce;

  // Function to search for a location based on user input
  void searchForLocation(String searchText) async {
    // Send an HTTP GET request to retrieve location data
    final response = await http.get(
      Uri.parse(
          'https://mvvvip1.defas-fgi.de/mvv/XML_STOPFINDER_REQUEST?language=de&outputFormat=RapidJSON&type_sf=any&name_sf=$searchText'),
    );

    setState(() {
      if (response.statusCode == 200) {
        // Decode the response data
        String responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);

        // Check if the response contains 'locations' and is not null
        if (data.containsKey('locations') && data['locations'] != null) {
          // Update searchResults with location data
          searchResults = List<Map<String, dynamic>>.from(data['locations']);
        }
      } else {
        // Clear searchResults if no locations are found
        searchResults.clear();
      }
    });
  }

  // Function to handle text input changes with debouncing
  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      searchForLocation(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          title: const Column(
            children: [
              Text(
                'Fahrplan',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Stack(children: [
                Container(
                    height: 100,
                    decoration: BoxDecoration(color: Colors.white)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          onSearchTextChanged(searchController.text);
                        },
                        decoration: InputDecoration(
                            helperText: 'z.B. Bahnhof, Adresse',
                            hintText: 'Startpunkt',
                            contentPadding: EdgeInsets.all(15.0),
                            prefixIcon: Icon(Icons.adjust),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    // Show a clear button when there is text in the TextField
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        // Clear the TextField and search results
                                        searchController.clear();
                                        searchResults.clear();
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[200]),
                      ),
                    ],
                  ),
                ),
              ]),
              Expanded(
                  child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  final name = (result['disassembledName'] ?? result['name']);
                  final parent = result['parent'];
                  final locationName = parent['name'];

                  IconData iconData;
                  String type;

                  // Determine the icon and type based on the result's 'type'
                  switch (result['type']) {
                    case 'suburb':
                      iconData = Icons.location_city;
                      type = 'Vorort';
                      break;
                    case 'poi':
                      iconData = Icons.location_on;
                      type = 'Sehenswürdigkeit';
                      break;
                    case 'singlehouse':
                      iconData = Icons.home;
                      type = 'Haus';
                      break;
                    case 'stop':
                      iconData = Icons.directions_bus;
                      type = 'Haltestelle';
                      break;
                    case 'street':
                      iconData = Icons.signpost;
                      type = 'Straße';
                      break;
                    default:
                      iconData = Icons.not_listed_location;
                      type = result['type'];
                  }

                  return Card(
                    elevation: 2.0,
                    margin:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                      leading: Container(
                        width: 40,
                        height: 35,
                        child: Icon(
                          iconData,
                          size: 25,
                          color: Colors.blue[800],
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(type, style: TextStyle(fontSize: 12.0)),
                          Text(
                            '$locationName',
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Set the TextField value and trigger a search
                        setState(() {
                          searchController.text = name;
                        });
                        searchForLocation(searchController.text);
                      },
                    ),
                  );
                },
              )),
            ],
          ),
        ));
  }
}
