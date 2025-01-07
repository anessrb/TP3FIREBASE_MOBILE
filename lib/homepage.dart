import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_content_page.dart';
import 'quiz_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        backgroundColor: Colors.blue[300],
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Thèmes disponibles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('questions')
                    .snapshots(), // Utiliser snapshots() au lieu de get().asStream()
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun thème disponible'),
                    );
                  }

                  // Récupérer tous les thèmes uniques de manière sûre
                  Set<String> themes = snapshot.data!.docs
                      .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final theme = data['theme']?.toString() ?? 'Général';
                    return theme;
                  })
                      .toSet(); // Utiliser toSet() pour avoir des thèmes uniques

                  return ListView.builder(
                    itemCount: themes.length,
                    itemBuilder: (context, index) {
                      String theme = themes.elementAt(index);
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            theme,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.quiz, color: Colors.blue[700]),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizPage(
                                  title: 'Quiz $theme',
                                  theme: theme,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajouter un nouveau thème',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddContentPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddThemePage extends StatefulWidget {
  const AddThemePage({Key? key}) : super(key: key);

  @override
  State<AddThemePage> createState() => _AddThemePageState();
}

class _AddThemePageState extends State<AddThemePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  bool _isCorrect = true;
  String? _selectedTheme;
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _loadExistingThemes();
  }

  Future<void> _loadExistingThemes() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('questions')
        .get();

    if (mounted) {
      // Les thèmes seront chargés via le StreamBuilder
    }
  }

  Widget _buildThemeSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('questions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Une erreur est survenue: ${snapshot.error}');
        }

        Set<String> themes = {};
        if (snapshot.hasData) {
          themes = snapshot.data!.docs
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['theme']?.toString() ?? 'Général';
          })
              .where((theme) => theme != null)
              .toSet();
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 16),
                if (themes.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTheme,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          border: InputBorder.none,
                        ),
                        hint: const Text('Sélectionner un thème existant'),
                        items: themes.map((String theme) {
                          return DropdownMenuItem<String>(
                            value: theme,
                            child: Text(theme),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedTheme = newValue;
                            _themeController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ou créer un nouveau thème',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _themeController,
                  decoration: InputDecoration(
                    labelText: 'Nom du nouveau thème',
                    labelStyle: TextStyle(color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _selectedTheme = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Texte de la question',
                labelStyle: TextStyle(color: Colors.blue[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une question';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imagePathController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'image (ex: quiz1.jpg)',
                labelStyle: TextStyle(color: Colors.blue[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom d\'image';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<bool>(
                  value: _isCorrect,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Vrai')),
                    DropdownMenuItem(value: false, child: Text('Faux')),
                  ],
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isCorrect = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuestion() {
    if (_formKey.currentState!.validate()) {
      String theme = _selectedTheme ?? _themeController.text;
      if (theme.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Veuillez sélectionner ou créer un thème'),
            backgroundColor: Colors.blue[400],
          ),
        );
        return;
      }

      setState(() {
        questions.add({
          'questionText': _questionController.text,
          'isCorrect': _isCorrect,
          'imagePath': _imagePathController.text,
          'theme': theme,
        });
        _questionController.clear();
        _imagePathController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question ajoutée'),
          backgroundColor: Colors.blue[400],
        ),
      );
    }
  }

  Future<void> _saveQuestions() async {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoutez au moins une question'),
          backgroundColor: Colors.blue[400],
        ),
      );
      return;
    }

    try {
      for (var question in questions) {
        await FirebaseFirestore.instance
            .collection('questions')
            .add(question);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Questions sauvegardées avec succès'),
            backgroundColor: Colors.blue[400],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.blue[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter du contenu'),
        backgroundColor: Colors.blue[300],
        elevation: 0,
      ),
      backgroundColor: Colors.blue[50],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildThemeSection(),
              _buildQuestionForm(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Ajouter la question',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _addQuestion,
              ),
              if (questions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Questions ajoutées: ${questions.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Sauvegarder toutes les questions',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _saveQuestions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _themeController.dispose();
    _questionController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }
}