import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquarium App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blue,
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarVisible = false;
  bool _showAddFishPage = false;
  bool _showChangeSettingsPage = false;
  int _fishCount = 1;
  final bkm = AudioPlayer();
  final fp = AudioPlayer();
  List<Map<String, dynamic>> _fishSettings = [];

  Timer? _timer;
  Map<String, dynamic> _fishPositions = {};
  double boxWidth = 160;
  double boxHeight = 145;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _loadFishSettings();
    _startFishTimer();
    bkm.setLoopMode(LoopMode.all);
    bkm.setAsset('src/bgm.mp3');
    bkm.play();
    fp.setLoopMode(LoopMode.all);
    fp.setAsset('src/fp.mp3');
    fp.play();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startFishTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateFishMovements();
    });
  }

  Future<void> _updateFishMovements() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> fishData = await dbHelper.getFishSettings();

    setState(() {
      if (fishData.isEmpty) {
        _fishPositions.clear();
      }

      for (var fish in fishData) {
        String fishName = fish['name'];
        double speed = double.tryParse(fish['speed'] ?? '0') ?? 0;

        if (!_fishPositions.containsKey(fishName)) {
          _fishPositions[fishName] = {
            'x': random.nextDouble() * (boxWidth - 30),
            'y': random.nextDouble() * (boxHeight - 30),
            'dx': (random.nextDouble() * 2 - 1),
            'dy': (random.nextDouble() * 2 - 1),
          };
        }

        if (speed > 0) {
          _moveFishWithinBounds(fishName, speed);
        }
      }
    });
  }

  void _moveFishWithinBounds(String fishName, double speed) {
    double x = _fishPositions[fishName]['x'];
    double y = _fishPositions[fishName]['y'];
    double dx = _fishPositions[fishName]['dx'];
    double dy = _fishPositions[fishName]['dy'];

    if (random.nextInt(100) < 2) {
      dx = -dx;
      dy = -dy;
    }

    x += dx * speed;
    y += dy * speed;

    if (x < 0 || x > boxWidth - 30) {
      dx = -dx;
      x = x < 0 ? 0 : (boxWidth - 30);
    }
    if (y < 0 || y > boxHeight - 30) {
      dy = -dy;
      y = y < 0 ? 0 : (boxHeight - 30);
    }

    _fishPositions[fishName]['x'] = x;
    _fishPositions[fishName]['y'] = y;
    _fishPositions[fishName]['dx'] = dx;
    _fishPositions[fishName]['dy'] = dy;
  }

  void _moveFish(String fishName, double speed) {
    double x = _fishPositions[fishName]['x'];
    double y = _fishPositions[fishName]['y'];
    double dx = _fishPositions[fishName]['dx'];
    double dy = _fishPositions[fishName]['dy'];

    x += dx * speed;
    y += dy * speed;

    if (x < 0 || x > boxWidth - 30) {
      dx = -dx;
    }
    if (y < 0 || y > boxHeight - 30) {
      dy = -dy;
    }

    _fishPositions[fishName]['x'] = x;
    _fishPositions[fishName]['y'] = y;
    _fishPositions[fishName]['dx'] = dx;
    _fishPositions[fishName]['dy'] = dy;
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _navigateToAddFish() {
    setState(() {
      _showAddFishPage = true;
      _showChangeSettingsPage = false;
    });
  }

  void _navigateBack() {
    setState(() {
      _showAddFishPage = false;
      _showChangeSettingsPage = false;
    });
  }

  void _incrementFishCount() async {
    _fishCount++;
    await _loadFishSettings();
    setState(() {
      _showAddFishPage = false;
    });
  }

  Future<void> _loadFishSettings() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> settings = await dbHelper.getFishSettings();
    setState(() {
      _fishSettings = settings;
      _fishCount = _fishSettings.length + 1;
    });
  }

  Future<void> _resetFishSettings() async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper();

      await dbHelper.resetDatabase();

      setState(() {
        _fishSettings.clear();
        _fishPositions.clear();
        _fishCount = 1;
      });

      await _loadFishSettings();
      if (_showChangeSettingsPage) {
        setState(() {
          _fishSettings = [];
        });
      }

      print('All fish settings and positions have been reset.');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  void _navigateToChangeSettings() {
    setState(() async {
      await _loadFishSettings();
      _showChangeSettingsPage = true;
      _showAddFishPage = false;
    });
  }

 void _updateFishSettings(String fishName) {
  String? selectedColor;
  String? selectedKind;
  
   TextEditingController speedController = TextEditingController();

   Map<String, dynamic> fishData = _fishSettings.firstWhere(
    (fish) => fish['name'] == fishName,
    orElse: () => <String, dynamic>{}  );

  if (fishData.isNotEmpty) {
    selectedColor = fishData['color'];    selectedKind = fishData['kind'];  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text('Change Settings for $fishName', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: speedController,                  decoration: InputDecoration(
                    labelText: 'Fish Speed',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedColor,
                  hint: Text('Select Fish Color', style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.black.withOpacity(0.7),
                  items: ['Default', 'Red', 'Blue', 'Green', 'Yellow'].map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(color, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedKind,
                  hint: Text('Select Fish Kind', style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.black.withOpacity(0.7),
                  items: ['Fish A', 'Fish B', 'Fish C'].map((kind) {
                    return DropdownMenuItem(
                      value: kind,
                      child: Text(kind, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedKind = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                                   String speed = speedController.text.isNotEmpty ? speedController.text : '0.2';
                                   DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.updateFishSetting(fishName, speed, selectedColor, selectedKind);

                                   await _loadFishSettings(); 
                  Navigator.of(context).pop();                },
                child: Text('Save', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('src/bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Positioned(
            left: 155,
            top: 487,
            child: Image.asset(
              'src/fire.gif',
              width: 100,
              height: 80,
            ),
          ),
          Positioned(
            left: 140,
            top: 487,
            child: Image.asset(
              'src/fire.gif',
              width: 100,
              height: 80,
            ),
          ),
          Positioned(
            left: 165,
            top: 487,
            child: Image.asset(
              'src/fire.gif',
              width: 100,
              height: 80,
            ),
          ),
          Positioned(
            top: 240,
            left: 125,
            child: Container(
              width: boxWidth,
              height: boxHeight,
              /*decoration: BoxDecoration(
                border: Border.all(
                color: Colors.blue, width: 3),),*/
              child: Stack(
                children: _fishPositions.entries.map((entry) {
                  String fishName = entry.key;
                  double x = entry.value['x'];
                  double y = entry.value['y'];
                  Map<String, dynamic> fishData = _fishSettings.firstWhere(
                      (fish) => fish['name'] == fishName,
                      orElse: () => <String, dynamic>{});

                  if (fishData.isEmpty) {
                    return Container();
                  }

                  String fishKind = fishData['kind'] ?? 'Fish A';
                  String fishColor = fishData['color'] ?? 'Default';
                  String fishImage;

                  if (fishKind == 'Fish A') {
                    fishImage = 'src/fish1.png';
                  } else if (fishKind == 'Fish B') {
                    fishImage = 'src/fish2.png';
                  } else if (fishKind == 'Fish C') {
                    fishImage = 'src/fish3.png';
                  } else {
                    fishImage = 'src/fish1.png';
                  }

                  Color? filterColor;
                  if (fishColor == 'Red') {
                    filterColor = Colors.red;
                  } else if (fishColor == 'Blue') {
                    filterColor = Colors.blue;
                  } else if (fishColor == 'Green') {
                    filterColor = Colors.green;
                  } else if (fishColor == 'Yellow') {
                    filterColor = Colors.yellow;
                  } else {
                    filterColor = null;
                  }

                  return Positioned(
                    left: x,
                    top: y,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(_fishPositions[fishName]['dx'] > 0 ? -1.0 : 1.0,
                            1.0),
                      child: ColorFiltered(
                        colorFilter: filterColor != null
                            ? ColorFilter.mode(filterColor, BlendMode.modulate)
                            : ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
                        child: Image.asset(
                          fishImage,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: _isSidebarVisible ? 0 : -250,
            top: 0,
            bottom: 0,
            width: 250,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: _showAddFishPage
                  ? AddFishPage(
                      onBack: _navigateBack,
                      fishName: 'Fish $_fishCount',
                      onSave: _incrementFishCount,
                    )
                  : _showChangeSettingsPage
                      ? Column(
                          children: [
                            AppBar(
                              title: Text('Change Settings',
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.black.withOpacity(0.7),
                              leading: IconButton(
                                icon:
                                    Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: _navigateBack,
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                children: _fishSettings.map((fish) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Container(
                                      width: 180,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _updateFishSettings(fish['name']);
                                        },
                                        child: Text(
                                          fish['name'],
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 20),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(height: 50),
                            ListTile(
                              title: Text('Add Fish',
                                  style: TextStyle(color: Colors.white)),
                              onTap: _navigateToAddFish,
                            ),
                            ListTile(
                              title: Text('Change Settings',
                                  style: TextStyle(color: Colors.white)),
                              onTap: _navigateToChangeSettings,
                            ),
                            Spacer(),
                            ListTile(
                              title: Text('Reset',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () async {
                                bool? confirmReset = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: Text('Reset Database',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      content: Text(
                                        'Are you sure you want to reset all settings? This action cannot be undone.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: Text('Reset',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmReset == true) {
                                  await _resetFishSettings();
                                  setState(() {
                                    _fishCount = 1;
                                  });
                                  print(
                                      'Database reset: All fish settings have been deleted.');
                                }
                              },
                            ),
                          ],
                        ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            top: 40,
            left: _isSidebarVisible ? 250 : 10,
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isSidebarVisible ? '<' : '>',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddFishPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  final String fishName;

  AddFishPage({
    required this.onBack,
    required this.onSave,
    required this.fishName,
  });

  @override
  _AddFishPageState createState() => _AddFishPageState();
}

class _AddFishPageState extends State<AddFishPage> {
  final TextEditingController _speedController = TextEditingController();
  String? _selectedColor;
  String? _selectedKind;
  final List<String> _colors = ['Default', 'Red', 'Blue', 'Green', 'Yellow'];
  final List<String> _kinds = ['Fish A', 'Fish B', 'Fish C'];

  void _saveSettings() async {
       String speed = _speedController.text.isNotEmpty ? _speedController.text : '.2';     String color = _selectedColor ?? 'Default';     String kind = _selectedKind ?? 'Fish A';    
       DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> allFishSettings = await dbHelper.getFishSettings();
    
       if (allFishSettings.length >= 10) {
      _showMaxFishMessage();
      return;    }

       await dbHelper.insertFishSetting(widget.fishName, speed, color, kind);
    print('Saving Fish: Name = ${widget.fishName}, Speed = $speed, Color = $color, Kind = $kind');

       print('--- Database Contents ---');
    for (var fish in allFishSettings) {
      print('Fish Name: ${fish['name']}, Speed: ${fish['speed']}, Color: ${fish['color']}, Kind: ${fish['kind']}');
    }
    print('--- End of Database ---');

    widget.onSave();
  }

  void _showMaxFishMessage() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,         title: Text(
          'Limit Reached',
          style: TextStyle(color: Colors.white),        ),
        content: Text(
          'Maximum limit is 10 fishes in this aquarium.',
          style: TextStyle(color: Colors.white),        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.white),            ),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title:
              Text('Add Fish Settings', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black.withOpacity(0.7),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.fishName,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                TextField(
                  controller: _speedController,
                  decoration: InputDecoration(
                    labelText: 'Fish Speed',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  hint: Text('Select Fish Color',
                      style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.black.withOpacity(0.7),
                  items: _colors.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(color, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedKind,
                  hint: Text('Select Fish Kind',
                      style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.black.withOpacity(0.7),
                  items: _kinds.map((kind) {
                    return DropdownMenuItem(
                      value: kind,
                      child: Text(kind, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKind = value;
                    });
                  },
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: Text('Save Settings',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
