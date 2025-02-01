import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
      home: QuizHomePage(),
    );
  }
}

class QuizHomePage extends StatefulWidget {
  @override
  _QuizHomePageState createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  List<dynamic> _questions = [];
  Map<int, String?> _selectedAnswers = {};
  int _score = 0;
  bool _isLoading = true;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    fetchQuizData();
    loadHighScore();
  }

  Future<void> fetchQuizData() async {
    try {
      final response = await http.get(Uri.parse('https://api.jsonserve.com/Uw5CrX'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _questions = data['questions'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load quiz data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching quiz data: $e');
    }
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highscore') ?? 0;
    });
  }

  void _submitQuiz() async {
    _score = 0;
    _selectedAnswers.forEach((index, answer) {
      if (answer == _questions[index]['correct']) {
        _score += 10;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    if (_score > _highScore) {
      await prefs.setInt('highscore', _score);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResult(score: _score, highScore: _highScore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz App'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_questions.isEmpty
          ? Center(child: Text('No questions available.'))
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...List.generate(_questions.length, (index) {
                return QuizQuestion(
                  question: _questions[index],
                  selectedAnswer: _selectedAnswers[index],
                  onAnswerSelected: (answer) {
                    setState(() {
                      _selectedAnswers[index] = answer;
                    });
                  },
                );
              }),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitQuiz,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Submit Quiz'),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

class QuizQuestion extends StatelessWidget {
  final Map<String, dynamic> question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;

  QuizQuestion({
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['description'] ?? 'No question available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...List<Widget>.from(
              (question['options'] as List).map<Widget>((option) {
                // Extracting only the 'description' for display
                return RadioListTile<String>(
                  title: Text(option['description']),
                  value: option['description'],
                  groupValue: selectedAnswer,
                  onChanged: (value) => onAnswerSelected(value!),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizResult extends StatelessWidget {
  final int score;
  final int highScore;

  QuizResult({required this.score, required this.highScore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quiz Completed!\nYour Score: $score',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'High Score: $highScore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.green),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => QuizHomePage()),
                );
              },
              child: Text('Restart Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
