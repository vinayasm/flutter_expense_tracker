import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

void main() => runApp(ExpenseTrackerApp());

class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: ExpenseHomePage(),
    );
  }
}

class Expense {
  String title;
  double amount;
  DateTime date;

  Expense({required this.title, required this.amount, required this.date});
}

class ExpenseHomePage extends StatefulWidget {
  @override
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  List<Expense> _expenses = [];
  double _monthlyBudget = 0;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  Future<void> _showBudgetExceededAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // force user to tap OK
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Budget Exceeded'),
          content: Text('Cannot add this expense because it exceeds your monthly budget.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addExpense() async {
    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) return;

    if (_monthlyBudget > 0 && (_totalExpense + enteredAmount) > _monthlyBudget) {
      await _showBudgetExceededAlert();
      return; // Do not add expense
    }

    final newExpense = Expense(
      title: enteredTitle,
      amount: enteredAmount,
      date: DateTime.now(),
    );

    setState(() {
      _expenses.add(newExpense);
    });

    _titleController.clear();
    _amountController.clear();

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense added successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // so keyboard doesn't cover inputs
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addExpense,
                child: Text('Add Expense'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetBudgetSheet() {
    final _budgetController = TextEditingController(
      text: _monthlyBudget > 0 ? _monthlyBudget.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _budgetController,
                decoration: InputDecoration(labelText: 'Set Monthly Budget (₹)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final enteredBudget = double.tryParse(_budgetController.text);
                  if (enteredBudget != null && enteredBudget > 0) {
                    setState(() {
                      _monthlyBudget = enteredBudget;
                    });
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Monthly budget set successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('Set Budget'),
              ),
            ],
          ),
        );
      },
    );
  }

  double get _totalExpense {
    return _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get _remainingBudget {
    return (_monthlyBudget - _totalExpense).clamp(0, double.infinity);
  }

  void _navigateToCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CalculatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetUsed = _monthlyBudget > 0 ? (_totalExpense / _monthlyBudget) : 0.0;
    final budgetColor = budgetUsed > 1
        ? Colors.red
        : budgetUsed > 0.75
        ? Colors.orange
        : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.calculate),
            tooltip: 'Calculator',
            onPressed: _navigateToCalculator,
          ),
          IconButton(
            icon: Icon(Icons.account_balance_wallet),
            tooltip: 'Set Monthly Budget',
            onPressed: _showSetBudgetSheet,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  'Total Expense',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                trailing: Text(
                  '₹${_totalExpense.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: Colors.indigo),
                ),
              ),
            ),
            if (_monthlyBudget > 0)
              Card(
                color: budgetColor.withOpacity(0.1),
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    'Monthly Budget: ₹${_monthlyBudget.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: budgetUsed.clamp(0.0, 1.0),
                        color: budgetColor,
                        backgroundColor: Colors.grey[300],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Remaining Budget: ₹${_remainingBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: budgetColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _expenses.isEmpty
                  ? Center(
                child: Text(
                  'No expenses added yet!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
                  : ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (ctx, index) {
                  final expense = _expenses[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    elevation: 3,
                    child: ListTile(
                      title: Text(expense.title),
                      subtitle: Text(DateFormat.yMMMd().format(expense.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExpense(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseSheet,
        tooltip: 'Add Expense',
        child: Icon(Icons.add),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = '';
  String result = '0';

  void _onPressed(String value) {
    setState(() {
      if (value == 'C') {
        expression = '';
        result = '0';
      } else if (value == '=') {
        _calculateResult();
      } else {
        expression += value;
      }
    });
  }

  void _calculateResult() {
    try {
      // sanitize expression, only allow digits and operators + - * / .
      final sanitized = expression.replaceAll(RegExp('[^0-9.+\\-*/]'), '');
      Parser p = Parser();
      Expression exp = p.parse(sanitized);
      double eval = exp.evaluate(EvaluationType.REAL, ContextModel());

      setState(() {
        result = eval.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        result = 'Error';
      });
    }
  }

  Widget _buildButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.indigo,
            padding: EdgeInsets.symmetric(vertical: 20),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 24),
          ),
          onPressed: () => _onPressed(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculator'),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Text(
                expression,
                style: TextStyle(fontSize: 24, color: Colors.black87),
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Text(
                result,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            Divider(),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('/', color: Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('*', color: Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('-', color: Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('C', color: Colors.red),
                      _buildButton('+', color: Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: Text(
                            '=',
                            style: TextStyle(fontSize: 24),
                          ),
                          onPressed: _calculateResult,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
