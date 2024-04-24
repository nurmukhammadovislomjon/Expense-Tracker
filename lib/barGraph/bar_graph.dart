// ignore_for_file: unused_local_variable, unused_field

import 'package:expense_tracker/barGraph/individual_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyBarGraph extends StatefulWidget {
  const MyBarGraph(
      {super.key, required this.monthlySummary, required this.startMonth});
  final List<double> monthlySummary;
  final int startMonth;

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  List<IndividualBar> barData = [];

  void initializeBarData() {
    barData = List.generate(
      widget.monthlySummary.length,
      (index) => IndividualBar(
        x: index,
        y: widget.monthlySummary[index],
      ),
    );
  }

  double calculateMax() {
    double max = 500;
    widget.monthlySummary.sort();
    max = widget.monthlySummary.last * 1.05;

    if (max < 500) {
      return 500;
    } else {
      return max;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp)=>scrollToEnd());
  }

  final ScrollController _scrollController = ScrollController();

  void scrollToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeBarData();

    double barWidth = 20;
    double scaleBetweenBars = 15;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SizedBox(
          width: barWidth * barData.length +
              scaleBetweenBars * (barData.length - 1),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: calculateMax(),
              gridData: const FlGridData(
                show: false,
              ),
              borderData: FlBorderData(
                show: false,
              ),
              titlesData: const FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: getBottomTitlesWidget,
                    reservedSize: 24,
                  ),
                ),
              ),
              barGroups: barData
                  .map(
                    (data) => BarChartGroupData(
                      x: data.x,
                      barRods: [
                        BarChartRodData(
                            toY: data.y,
                            width: 20,
                            borderRadius: BorderRadius.circular(
                              4,
                            ),
                            color: Colors.grey.shade800,
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: calculateMax(),
                              color: Colors.white,
                            )),
                      ],
                    ),
                  )
                  .toList(),
              alignment: BarChartAlignment.center,
              groupsSpace: scaleBetweenBars,
            ),
          ),
        ),
      ),
    );
  }
}

Widget getBottomTitlesWidget(double value, TitleMeta meta) {
  const textStyle = TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  String text;
  switch (value.toInt() % 12) {
    case 0:
      text = "J";
      break;
    case 1:
      text = "F";
      break;
    case 2:
      text = "M";
      break;
    case 3:
      text = "A";
      break;
    case 4:
      text = "M";
      break;
    case 5:
      text = "J";
      break;
    case 6:
      text = "J";
      break;
    case 7:
      text = "A";
      break;
    case 8:
      text = "S";
      break;
    case 9:
      text = "O";
      break;
    case 10:
      text = "N";
      break;
    case 11:
      text = "D";
      break;
    default:
      text = '';
      break;
  }
  return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: textStyle,
      ));
}
