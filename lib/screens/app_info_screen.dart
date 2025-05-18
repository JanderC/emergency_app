import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Cómo funciona la aplicación?'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 20),
            Text(
              'Sistema de Gestión de Emergencias para Rubio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Esta aplicación fue creada con compromiso y visión ciudadana por los estudiantes Geormary Camargo, Erika Grimaldo y Edixon Bautista. '
              'El objetivo principal es brindar una herramienta tecnológica que permita a los ciudadanos del municipio Rubio reportar emergencias '
              'de manera rápida, eficiente y segura.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20),
            Text(
              '¿Cómo funciona?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Cualquier ciudadano puede ingresar a la app y reportar una emergencia (accidente, incendio, emergencia médica, etc.).\n'
              '• Los bomberos del municipio reciben la notificación en tiempo real.\n'
              '• Los incidentes son gestionados por el cuerpo de bomberos, quienes pueden marcar el estado de cada emergencia.\n'
              '• El usuario puede ver el estado de su emergencia y saber cuándo fue atendida.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '¿Por qué es importante?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'En situaciones de emergencia, cada segundo cuenta. Esta app permite ahorrar tiempo valioso al eliminar intermediarios y conectar directamente a la ciudadanía con los bomberos locales.\n\n'
              'Además, fortalece la relación entre comunidad y organismos de respuesta, mejora la eficiencia operativa y ayuda a reducir los tiempos de atención.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20),
            Text(
              'Compromiso con la comunidad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Este proyecto representa el deseo de los jóvenes creadores de aportar al desarrollo y bienestar de su comunidad. '
              'A través de la tecnología buscan mejorar la capacidad de respuesta ante emergencias y fomentar una ciudadanía más conectada y participativa.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 30),
            Center(
              child: Text(
                '“Salvar una vida puede comenzar con un solo clic.”',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
