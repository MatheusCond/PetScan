import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para selecionar imagens da galeria ou câmera
import 'package:firebase_storage/firebase_storage.dart'; // Para armazenar imagens no Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // Para armazenar informações no Firestore
import 'dart:io'; // Para manipulação de arquivos
import 'dart:convert'; // Para codificar a imagem em Base64
import 'package:http/http.dart' as http; // Para requisições HTTP

class TelaCaptura extends StatefulWidget {
  const TelaCaptura({Key? key}) : super(key: key);

  @override
  _TelaCapturaState createState() => _TelaCapturaState();
}

class _TelaCapturaState extends State<TelaCaptura> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image; // Para armazenar a imagem selecionada

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
      await _uploadImageToFirebase(_image!);
      await _sendToGemini(
          _image!); // Chama a função para enviar a imagem ao Gemini AI
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    // Faz o upload da imagem para o Firebase Storage
    final storageRef =
        FirebaseStorage.instance.ref().child('images/${image.name}');
    await storageRef.putFile(File(image.path));
    // Armazena a URL da imagem no Firestore
    final url = await storageRef.getDownloadURL();
    await FirebaseFirestore.instance.collection('pets').add({'imageUrl': url});
  }

  Future<void> _sendToGemini(XFile image) async {
    // Aqui você deve implementar a lógica de integração com o Gemini AI
    final response = await http.post(
      Uri.parse('URL_DA_API_DO_GEMINI'),
      headers: {
        'Authorization': 'Bearer SEU_TOKEN',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': base64Encode(await File(image.path).readAsBytes()),
        // Outros parâmetros necessários pela API
      }),
    );

    if (response.statusCode == 200) {
      // Sucesso - processe a resposta aqui
      final data = jsonDecode(response.body);
      // Exiba ou utilize os dados retornados da API
    } else {
      // Trate erros
      print('Erro ao enviar para Gemini: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213597),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              '', // O caminho para a logo do PETSCAN
              height: 50,
            ),
            const SizedBox(width: 10),
            const Text(
              'PETSCAN',
              style: TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Capture uma imagem do seu pet:',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF213597),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213597),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Capturar Imagem',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_image != null) ...[
              const Text(
                'Imagem capturada:',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF213597),
                ),
              ),
              const SizedBox(height: 10),
              Image.file(File(_image!.path), height: 200),
            ],
          ],
        ),
      ),
    );
  }
}
