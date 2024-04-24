// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:expense_tracker/barGraph/bar_graph.dart';
import 'package:expense_tracker/components/my_list_tile.dart';
import 'package:expense_tracker/database/expense_database.dart';
import 'package:expense_tracker/helper/helper_functions.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshDataGraph();
  }

  void openNewExpense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "name",
              ),
              controller: nameController,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: "amount",
              ),
              controller: amountController,
            ),
          ],
        ),
        actions: [
          cancelButton(),
          newExpenseButton(),
        ],
      ),
    );
  }

  void openDeleteBox(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense?"),
        actions: [
          cancelButtonOk(),
          deleteExpenseButton(id),
        ],
      ),
    );
  }

  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? calculateCurrentMonthtotal;

  void refreshDataGraph() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .canculateMonthyTotals();

    calculateCurrentMonthtotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateMonthyTotal();
  }

  Widget cancelButtonOk() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text("Cancel"),
    );
  }

  Widget deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        await context.read<ExpenseDatabase>().deleteExpense(id);
        Navigator.pop(context);
        refreshDataGraph();
      },
      child: const Text("Delete"),
    );
  }

  Widget cancelButton() {
    return MaterialButton(
      onPressed: () {
        nameController.clear();
        amountController.clear();
        Navigator.pop(context);
      },
      child: const Text("Cancel"),
    );
  }

  Widget newExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          Expense newExpense = Expense(
              name: nameController.text,
              amount: convertStringToDouble(amountController.text),
              date: DateTime.now());
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);
          nameController.clear();
          amountController.clear();
          Navigator.pop(context);
          refreshDataGraph();
        }
      },
      child: const Text("Create"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;
        int monthCount = calculateMonthCount(
            startYear, startMonth, currentYear, currentMonth);

        List<Expense> currentMonthExpenses = value.allExpense.where((element) {
          return element.date.year == currentYear &&
              element.date.month == currentMonth;
        }).toList();
        return Scaffold(
            backgroundColor: Colors.grey.shade300,
            floatingActionButton: FloatingActionButton(
              onPressed: () => openNewExpense(),
              child: const Icon(
                Icons.add,
              ),
            ),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: FutureBuilder<double>(
                future: calculateCurrentMonthtotal,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${snapshot.data!.toStringAsFixed(2)}",
                        ),
                        Text(getCurrentMonthName()),
                      ],
                    );
                  } else {
                    return const Text("loading..");
                  }
                },
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // const SizedBox(
                  //   height: 15,
                  // ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: FutureBuilder(
                      future: _monthlyTotalsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          Map<String, double> monthlyTotals =
                              snapshot.data ?? {};

                          List<double> monthlySummary =
                              List.generate(monthCount, (index) {
                            int year =
                                startYear + (startMonth + index - 1) ~/ 12;
                            int month = (startMonth + index - 1) % 12 + 1;

                            String yearMonthKey = '$year-$month';

                            return monthlyTotals[yearMonthKey] ?? 0.0;
                          });

                          return MyBarGraph(
                              monthlySummary: monthlySummary,
                              startMonth: startMonth);
                        } else {
                          return const Center(
                            child: Text("Loading.."),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentMonthExpenses.length,
                      itemBuilder: (context, index) {
                        int reversedIndex =
                            currentMonthExpenses.length - 1 - index;
                        Expense individualExpense = currentMonthExpenses[index];
                        return MyListTile(
                          title: individualExpense.name,
                          trailing: formatAmount(individualExpense.amount),
                          onEditPressed: (context) =>
                              openEditBox(individualExpense),
                          onDeletePressed: (context) =>
                              openDeleteBox(individualExpense.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  void openEditBox(Expense expense) {
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();
    nameController.text = existingName;
    amountController.text = existingAmount;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "name",
              ),
              controller: nameController,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: "amount",
              ),
              controller: amountController,
            ),
          ],
        ),
        actions: [
          cancelButton(),
          editExpenseButton(expense),
        ],
      ),
    );
  }

  Widget editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          Expense editedExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );

          int existingId = expense.id;
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, editedExpense);

          nameController.clear();
          amountController.clear();
          Navigator.pop(context);
          refreshDataGraph();
        }
      },
      child: const Text("Save"),
    );
  }
}
