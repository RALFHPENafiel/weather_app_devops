import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:http/http.dart' as http;

const String OPENWEATHER_API_KEY = '1446dd7c844a7158c080c5c9e7c3130e';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  TextEditingController _searchController = TextEditingController();

  Weather? _weather;
  String _timeOfDay = '';
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _getWeather("San Fernando, Pampanga");
  }

  void _getWeather(String cityName) {
    _wf.currentWeatherByCityName(cityName).then((w) {
      setState(() {
        _weather = w;
        _updateDaytimeStatus();
      });
    });
  }

  void _updateDaytimeStatus() {
    if (_weather != null) {
      DateTime now = DateTime.now();
      DateTime sunrise = _weather!.sunrise!;
      DateTime sunset = _weather!.sunset!;
      if (now.isAfter(sunrise) && now.isBefore(sunset)) {
        _timeOfDay = 'Daytime';
      } else {
        _timeOfDay = 'Nighttime';
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<String> suggestions = data.map((place) => place['display_name'].toString()).toList();
      setState(() {
        _suggestions = suggestions;
      });
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.cloud),
            SizedBox(width: 8),
            Text('Weather App'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: Colors.black),
                            onChanged: _searchLocation,
                            onSubmitted: (_) {
                              _handleSearch();
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter city name',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              prefixIcon: Icon(Icons.search, color: Colors.black), // Prefix icon
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildSuggestions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildUI(),
          ],
        ),
      ),
    );
  }

  void _handleSearch() {
    String cityName = _searchController.text;
    if (cityName.isNotEmpty) {
      _getWeather(cityName);
    }
  }

  Widget _buildSuggestions() {
    return _suggestions.isNotEmpty
        ? Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_suggestions[index]),
            onTap: () {
              String selectedLocation = _suggestions[index];
              _searchController.text = selectedLocation;
              _getWeather(selectedLocation);
              setState(() {
                _suggestions = [];
              });
            },
          );
        },
      ),
    )
        : SizedBox.shrink();
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _locationHeader(),
            SizedBox(height: 16),
            _dateTimeInfo(),
            SizedBox(height: 16),
            _weatherIcon(),
            SizedBox(height: 16),
            _currentTemp(),
            SizedBox(height: 16),
            _extraInfo(),
          ],
        ),
      ),
    );
  }

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Roboto', // Example font family
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = _weather!.date!;
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat("h:mm a").format(now),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'sans-serif', // Example font family
            ),
          ),
          SizedBox(height: 10),
          Text(
            DateFormat("EEEE, d MMM y").format(now),
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'sans-serif', // Example font family
            ),
          ),
          SizedBox(height: 10),
          Text(
            _timeOfDay,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'sans-serif', // Example font family
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherIcon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Container(
            color: Colors.blue,
            child: Image.network(
              "http://openweathermap.org/img/wn/${_weather?.weatherIcon}@2x.png",
              height: 120, // Increased height
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          _weather?.weatherDescription ?? "",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Roboto', // Example font family
          ),
        ),
      ],
    );
  }

  Widget _currentTemp() {
    return Center(
      child: Text(
        "${_weather?.temperature?.celsius?.toStringAsFixed(0)}° C",
        style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'sans-serif', // Example font family
        ),
      ),
    );
  }

  Widget _extraInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Max: ${_weather?.tempMax?.celsius?.toStringAsFixed(0)}° C",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'sans-serif', // Example font family
                  ),
                ),
                Text(
                  "Min: ${_weather?.tempMin?.celsius?.toStringAsFixed(0)}° C",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'sans-serif', // Example font family
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Wind: ${_weather?.windSpeed?.toStringAsFixed(0)}m/s",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'sans-serif', // Example font family
                  ),
                ),
                Text(
                  "Humidity: ${_weather?.humidity?.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'sans-serif', // Example font family
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
