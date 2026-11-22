import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/patient_service.dart';
import 'package:controle_clinica/utils/formatters.dart';
import 'package:controle_clinica/widgets/patient_health.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ficha do paciente. Recebe `{'patient_id': int}` como argumento de rota.
/// As informações de saúde são só exibidas aqui: quem as altera é o
/// profissional, na página do atendimento.
class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  Map<String, dynamic>? _patient;
  bool _loading = true;
  bool _started = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Os argumentos da rota só ficam disponíveis aqui, não no initState.
    if (_started) return;
    _started = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is Map ? args["patient_id"] : null;

    if (id is int) {
      _load(id);
    } else {
      _loading = false;
      _error = "Paciente não informado";
    }
  }

  Future<void> _load(int id) async {
    try {
      final list = await PatientService.getPatients();

      Map<String, dynamic>? found;

      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);

        if (map["patient_id"] == id) found = map;
      }

      if (!mounted) return;

      setState(() {
        _patient = found;
        _error = found == null ? "Paciente não encontrado" : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, Widget child) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _birthText(String raw) {
    if (raw.length < 10) return "";

    final date = DateTime.tryParse(raw.substring(0, 10));

    if (date == null) return "";

    final now = DateTime.now();
    var age = now.year - date.year;

    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }

    return "${DateFormat('dd/MM/yyyy').format(date)} ($age anos)";
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (p == null) {
      body = Center(child: Text(_error ?? "Paciente não encontrado"));
    } else {
      String text(String key) => (p[key] ?? "").toString();

      body = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${text("first_name")} ${text("last_name")}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _card(
              "Dados do paciente",
              Icons.person_outline,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info("Nascimento", _birthText(text("birth_date"))),
                  _info("Sexo", text("gender")),
                  _info("CPF", formatCpf(text("cpf"))),
                  _info("Telefone", formatPhone(text("phone"))),
                  _info("E-mail", text("email")),
                ],
              ),
            ),
            _card(
              "Informações de saúde",
              Icons.health_and_safety_outlined,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PatientHealthView(patient: p),
                  const SizedBox(height: 6),
                  const Text(
                    "Preenchidas e atualizadas pelo profissional durante o "
                    "atendimento.",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      '/schedule',
                      arguments: {'patient_id': p["patient_id"]},
                    ),
                icon: const Icon(Icons.event_available),
                label: const Text("Agendar procedimento"),
              ),
            ),
          ],
        ),
      );
    }

    return BasePage(title: "Paciente", userRole: "dentist", body: body);
  }
}
