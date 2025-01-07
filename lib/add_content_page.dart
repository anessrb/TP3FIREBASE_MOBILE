import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddContentPage extends StatefulWidget {
  const AddContentPage({Key? key}) : super(key: key);

  @override
  State<AddContentPage> createState() => _AddContentPageState();
}

class _AddContentPageState extends State<AddContentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  bool _isCorrect = true;
  String? _selectedTheme;
  List<Map<String, dynamic>> _questions = [];

  Widget _buildThemeSection() {
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('questions')
                  .snapshots(),
              builder: (context, snapshot) {
                Set<String> existingThemes = {};

                if (snapshot.hasData) {
                  existingThemes = snapshot.data!.docs
                      .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['theme']?.toString() ?? 'Général';
                  })
                      .where((theme) => theme.isNotEmpty)
                      .toSet();
                }

                if (existingThemes.isNotEmpty) {
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedTheme,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                          ),
                          hint: const Text('Sélectionner un thème existant'),
                          items: existingThemes.map((String theme) {
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
                      const SizedBox(height: 16),
                      Text(
                        'Ou créer un nouveau thème',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
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
              validator: (value) {
                if (_selectedTheme == null && (value == null || value.isEmpty)) {
                  return 'Veuillez sélectionner ou créer un thème';
                }
                return null;
              },
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
        _questions.add({
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
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoutez au moins une question'),
          backgroundColor: Colors.blue[400],
        ),
      );
      return;
    }

    try {
      for (var question in _questions) {
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
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          labelStyle: TextStyle(color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Veuillez entrer une question'
                            : null,
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
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Veuillez entrer un nom d\'image'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _isCorrect = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Ajouter la question',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Questions ajoutées: ${_questions.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Sauvegarder toutes les questions',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
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