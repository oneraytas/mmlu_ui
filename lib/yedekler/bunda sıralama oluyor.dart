import 'dart:convert';
import 'package:mmlu/sonuc_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaderboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LeaderboardPage(),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<SonucModel>> _sonucList;
  String? _selectedFilter;
  double _ortalamaFiltre = 0;
  String? _selectedSinav;
  bool _isAscending = true;
  String? _sortedColumn;

  @override
  void initState() {
    super.initState();
    _sonucList = _loadSonuclar();
  }

  Future<List<SonucModel>> _loadSonuclar() async {
    final String response = await rootBundle.loadString('assets/sonuclar.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => SonucModel.fromJson(json)).toList();
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _sortData(List<SonucModel> data, String column) {
    setState(() {
      if (_sortedColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _isAscending = true;
        _sortedColumn = column;
      }

      data.sort((a, b) {
        final dynamic valueA =
            column == 'Ortalama' ? a.ortalama : a.sinavSonuclari[column];
        final dynamic valueB =
            column == 'Ortalama' ? b.ortalama : b.sinavSonuclari[column];

        if (valueA == null) return 1;
        if (valueB == null) return -1;

        return _isAscending
            ? Comparable.compare(valueA, valueB)
            : Comparable.compare(valueB, valueA);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: FutureBuilder<List<SonucModel>>(
        future: _sonucList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else {
            List<SonucModel> data = snapshot.data!;

            if (_selectedFilter == 'Ortalama') {
              data = data
                  .where((sonuc) => sonuc.ortalama >= _ortalamaFiltre)
                  .toList();
            } else if (_selectedSinav != null && _selectedFilter != null) {
              data = data
                  .where((sonuc) =>
                      sonuc.sinavSonuclari[_selectedSinav!] != null &&
                      sonuc.sinavSonuclari[_selectedSinav!]! >= _ortalamaFiltre)
                  .toList();
            }

            List<String> sinavlar = data[0].sinavSonuclari.keys.toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        hint: const Text('Filtre Seçin'),
                        value: _selectedFilter,
                        items: [
                          const DropdownMenuItem(
                              value: 'Ortalama', child: Text('Ortalama')),
                          ...sinavlar.map((sinav) {
                            return DropdownMenuItem(
                              value: sinav,
                              child: Text(sinav),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value;
                            _selectedSinav = value != 'Ortalama' ? value : null;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      Text(
                          'Filtre Değeri: ${_ortalamaFiltre.toStringAsFixed(1)}'),
                      Expanded(
                        child: Slider(
                          value: _ortalamaFiltre,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _ortalamaFiltre.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _ortalamaFiltre = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Başlık Satırı
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            dataRowHeight: 60,
                            headingRowColor: MaterialStateProperty.all(
                                Colors.blue.withOpacity(0.1)),
                            headingTextStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            columnSpacing: 24,
                            columns: [
                              DataColumn(label: Text('Sıra')),
                              DataColumn(
                                label: GestureDetector(
                                  onTap: () => _sortData(data, 'Model'),
                                  child: Text('Model'),
                                ),
                              ),
                              if (_selectedFilter == 'Ortalama')
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortData(data, 'Ortalama'),
                                    child: Text('Ortalama'),
                                  ),
                                ),
                              ...sinavlar
                                  .map(
                                    (sinav) => DataColumn(
                                      label: GestureDetector(
                                        onTap: () => _sortData(data, sinav),
                                        child: Text(sinav),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                            rows: [],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                        // Veri Satırları
                        Expanded(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return DataTable(
                                    dataRowHeight: 60,
                                    headingRowColor: MaterialStateProperty
                                        .resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                      return Colors.transparent; // or null
                                    }),
                                    columnSpacing: 24,
                                    columns: [
                                      DataColumn(label: SizedBox.shrink()),
                                      DataColumn(label: SizedBox.shrink()),
                                      if (_selectedFilter == 'Ortalama')
                                        DataColumn(label: SizedBox.shrink()),
                                      ...sinavlar
                                          .map((sinav) => DataColumn(
                                              label: SizedBox.shrink()))
                                          .toList(),
                                    ],
                                    rows: data.asMap().entries.map(
                                      (entry) {
                                        int index = entry.key;
                                        SonucModel sonuc = entry.value;
                                        return DataRow(
                                          color: MaterialStateProperty
                                              .resolveWith<Color?>(
                                                  (Set<MaterialState> states) {
                                            if (index.isEven) {
                                              return Colors.blue
                                                  .withOpacity(0.1);
                                            }
                                            return Colors.white;
                                          }),
                                          cells: [
                                            DataCell(
                                                Text((index + 1).toString())),
                                            DataCell(
                                              GestureDetector(
                                                onTap: () {
                                                  _launchUrl(
                                                      'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_liderlik_tablosu');
                                                },
                                                child: Text(
                                                  sonuc.model,
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            if (_selectedFilter == 'Ortalama')
                                              DataCell(Text(sonuc.ortalama
                                                  .toStringAsFixed(2))),
                                            ...sinavlar.map((sinav) {
                                              return DataCell(
                                                GestureDetector(
                                                  onTap: () {
                                                    _launchUrl(
                                                        'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_model_cevaplari');
                                                  },
                                                  child: Text(
                                                    sonuc.sinavSonuclari[sinav]
                                                            ?.toStringAsFixed(
                                                                2) ??
                                                        '-',
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        );
                                      },
                                    ).toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
