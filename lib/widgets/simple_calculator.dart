import 'package:flutter/material.dart';

class SimpleCalculator extends StatefulWidget {
  const SimpleCalculator({super.key});

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  String _input = '';
  String _result = '';
  bool _hasError = false;

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _clear();
      } else if (buttonText == '=') {
        _calculate();
      } else if (buttonText == '⌫') {
        _backspace();
      } else {
        _appendInput(buttonText);
      }
    });
  }

  void _clear() {
    _input = '';
    _result = '';
    _hasError = false;
  }

  void _backspace() {
    if (_input.isNotEmpty) {
      _input = _input.substring(0, _input.length - 1);
    }
  }

  void _appendInput(String value) {
    // Reset if there was an error
    if (_hasError) {
      _input = '';
      _result = '';
      _hasError = false;
    }

    // Prevent multiple operators in a row
    if (_isOperator(value) && _input.isNotEmpty && _isOperator(_input[_input.length - 1])) {
      _input = _input.substring(0, _input.length - 1) + value;
    } else {
      _input += value;
    }
  }

  bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '×' || value == '÷';
  }

  void _calculate() {
    try {
      // Replace operators with their mathematical equivalents
      String expression = _input.replaceAll('×', '*').replaceAll('÷', '/');

      // Simple evaluation using dart:math
      List<String> parts = [];
      String currentNumber = '';
      String currentOperator = '';

      // Parse the expression
      for (int i = 0; i < expression.length; i++) {
        String char = expression[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (currentNumber.isNotEmpty) {
            parts.add(currentNumber);
            currentNumber = '';
          }
          parts.add(char);
        } else {
          currentNumber += char;
        }
      }

      if (currentNumber.isNotEmpty) {
        parts.add(currentNumber);
      }

      // Evaluate the expression
      if (parts.isEmpty) {
        _result = '';
        return;
      }

      double result = double.parse(parts[0]);

      for (int i = 1; i < parts.length; i += 2) {
        if (i + 1 >= parts.length) break;

        String operator = parts[i];
        double operand = double.parse(parts[i + 1]);

        switch (operator) {
          case '+':
            result += operand;
            break;
          case '-':
            result -= operand;
            break;
          case '*':
            result *= operand;
            break;
          case '/':
            if (operand == 0) {
              throw Exception('Division by zero');
            }
            result /= operand;
            break;
        }
      }

      // Format the result
      _result = result % 1 == 0 ? result.toInt().toString() : result.toString();
    } catch (e) {
      _result = 'Error';
      _hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _input,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _result,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _hasError ? Colors.red : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Buttons
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // First row - Clear and Backspace
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(child: _buildButton('C', isClear: true)),
                        Expanded(child: _buildButton('⌫', isBackspace: true)),
                      ],
                    ),
                  ),
                  // Number pad and operators in a fixed layout
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        // Row 1: 7, 8, 9, ÷
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildButton('7')),
                              Expanded(child: _buildButton('8')),
                              Expanded(child: _buildButton('9')),
                              Expanded(child: _buildButton('÷', isOperator: true)),
                            ],
                          ),
                        ),
                        // Row 2: 4, 5, 6, ×
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildButton('4')),
                              Expanded(child: _buildButton('5')),
                              Expanded(child: _buildButton('6')),
                              Expanded(child: _buildButton('×', isOperator: true)),
                            ],
                          ),
                        ),
                        // Row 3: 1, 2, 3, -
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildButton('1')),
                              Expanded(child: _buildButton('2')),
                              Expanded(child: _buildButton('3')),
                              Expanded(child: _buildButton('-', isOperator: true)),
                            ],
                          ),
                        ),
                        // Row 4: 0, ., =, +
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildButton('0')),
                              Expanded(child: _buildButton('.')),
                              Expanded(child: _buildButton('=', isEquals: true)),
                              Expanded(child: _buildButton('+', isOperator: true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {
    bool isOperator = false,
    bool isEquals = false,
    bool isClear = false,
    bool isBackspace = false,
  }) {
    Color backgroundColor;
    Color textColor;

    if (isOperator) {
      backgroundColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isEquals) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (isClear) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else if (isBackspace) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
    } else {
      backgroundColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.white;
      textColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        child: InkWell(
          onTap: () => _onButtonPressed(text),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: isOperator || isEquals || isClear || isBackspace ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
