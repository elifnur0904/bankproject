import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class grafikEkrani extends StatefulWidget {
  final String symbol;

  const grafikEkrani({ required this.symbol}) ;

  @override
  _grafikEkraniState createState() => _grafikEkraniState();
}

class _grafikEkraniState extends State<grafikEkrani> {
  List<FlSpot> chartData = [];
  String selectedInterval = '1d'; // Varsayılan zaman aralığı: 1 günlük

  @override
  void initState() {
    super.initState();
    bilgiGetirGrafik();
  }

  Future<void> bilgiGetirGrafik() async {
    final url = Uri.parse(
        'https://api.binance.com/api/v3/klines?symbol=${widget.symbol}&interval=$selectedInterval');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          chartData = data.asMap().entries.map<FlSpot>((e) {
            double x = e.key.toDouble();
            double y = double.tryParse(e.value[4]) ?? 0.0; // Kapanış fiyatı
            return FlSpot(x, y);
          }).toList();
        });
      } else {
        throw Exception('Veri yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grafik verisi yüklenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} Grafiği')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedInterval,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedInterval = value;
                  bilgiGetirGrafik(); // Yeni veri çek
                });
              }
            },
            items: const [
              DropdownMenuItem(value: '1h', child: Text('Saatlik')),
              DropdownMenuItem(value: '1d', child: Text('Günlük')),
              DropdownMenuItem(value: '1w', child: Text('Haftalık')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            color: Colors.blue,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
