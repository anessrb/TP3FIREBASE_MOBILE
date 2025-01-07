import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key, required this.title, required this.theme}) : super(key: key);
  final String title;
  final String theme;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<Map<String, dynamic>> _questions = [];

  void _handleAnswer(bool userChoice) {
    if (_questions[_currentQuestionIndex]['isCorrect'] == userChoice) {
      setState(() {
        _score++;
      });
      _showCorrectAnswerDialog();
    } else {
      _showWrongAnswerDialog();
    }
  }

  void _showCorrectAnswerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 10),
              const Text('Correct!', style: TextStyle(color: Colors.green)),
            ],
          ),
          content: const Text('Bien joué! Continue comme ça!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Suivant'),
              onPressed: () {
                Navigator.of(context).pop();
                _nextQuestion();
              },
            ),
          ],
        );
      },
    );
  }

  void _showWrongAnswerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700]),
              const SizedBox(width: 10),
              const Text('Incorrect', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: const Text('Ce n\'est pas la bonne réponse.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Suivant'),
              onPressed: () {
                Navigator.of(context).pop();
                _nextQuestion();
              },
            ),
          ],
        );
      },
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showResultPage();
    }
  }

  void _showResultPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          score: _score,
          total: _questions.length,
          onRestart: () {
            setState(() {
              _currentQuestionIndex = 0;
              _score = 0;
            });
          },
        ),
      ),
    );
  }

  Widget _buildImageContainer(String imagePath) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          'assets/$imagePath',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return const Center(
              child: Icon(Icons.error_outline, size: 50, color: Colors.red),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionContainer(String questionText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[200]!, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Question ${_currentQuestionIndex + 1}/${_questions.length}",
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue[900],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "Score: $_score",
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(bool isTrue, String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      onPressed: () => _handleAnswer(isTrue),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[300],
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('questions')
            .where('theme', isEqualTo: widget.theme)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue[300],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur: ${snapshot.error}",
                style: TextStyle(color: Colors.blue[700]),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Aucune question disponible pour ce thème.",
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          _questions = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'questionText': data['questionText'] ?? 'Question non disponible',
              'isCorrect': data['isCorrect'] ?? false,
              'imagePath': data['imagePath'] ?? '',
              'theme': data['theme'] ?? widget.theme,
            };
          }).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImageContainer(_questions[_currentQuestionIndex]['imagePath']),
                  const SizedBox(height: 20),
                  _buildQuestionContainer(_questions[_currentQuestionIndex]['questionText']),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAnswerButton(true, 'VRAI'),
                      _buildAnswerButton(false, 'FAUX'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;

  const ResultPage({
    Key? key,
    required this.score,
    required this.total,
    required this.onRestart,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playResultSound();
  }

  Future<void> _playResultSound() async {
    try {
      final percentage = (widget.score / widget.total) * 100;
      final storage = FirebaseStorage.instance;
      String soundPath;

      if (percentage >= 60) {
        soundPath = 'sounds/victory.mp3';
      } else {
        soundPath = 'sounds/defeat.mp3';
      }

      final soundUrl = await storage.ref(soundPath).getDownloadURL();
      setState(() {
        _isPlaying = true;
      });

      await _audioPlayer.play(UrlSource(soundUrl));

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      print('Erreur lors de la lecture du son: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.total) * 100;
    String message;
    Color messageColor;
    IconData resultIcon;

    if (percentage >= 80) {
      message = 'Excellent!';
      messageColor = Colors.blue[700]!;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 60) {
      message = 'Bien joué!';
      messageColor = Colors.blue;
      resultIcon = Icons.thumb_up;
    } else {
      message = 'Continue tes efforts!';
      messageColor = Colors.blue[300]!;
      resultIcon = Icons.stars;
    }

    return WillPopScope(
      onWillPop: () async {
        await _audioPlayer.stop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Résultats'),
          backgroundColor: Colors.blue[300],
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                resultIcon,
                size: 80,
                color: messageColor,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: messageColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Score final: ${widget.score} / ${widget.total}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue[400],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text(
                  'Recommencer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  _audioPlayer.stop();
                  widget.onRestart();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}