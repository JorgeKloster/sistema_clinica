import 'package:flutter/material.dart';
import 'package:controle_clinica/models/appointment.dart';

class AppointmentPopup {
  static void show(
    BuildContext context,
    Offset tapPosition,
    Appointment appointment,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        size.width - tapPosition.dx,
        size.height - tapPosition.dy,
      ),
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false, // disable default tap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appointment.patientName, // TODO: replace with patient name
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Responsável: ${appointment.doctorName}",
                style: const TextStyle(color: Colors.black87),
              ), // TODO: replace with doctor name
              Text(
                "Procedimento: ${appointment.type}",
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                "Dia: ${appointment.date.day}/${appointment.date.month}/${appointment.date.year}",
                style: const TextStyle(color: Colors.black87),
              ),
              Text(
                "Horário: ${appointment.startTime.hour}:${appointment.startTime.minute.toString().padLeft(2, '0')} "
                "- ${appointment.endTime.hour}:${appointment.endTime.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.black87),
              ),
              if (appointment.notes.isNotEmpty)
                Text(
                  appointment.notes,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context); // close popup
                      // TODO: remove appointment
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close popup
                      // TODO: navigate to appointment page
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Abrir",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.green,
                          size: 24, // 👈 bigger, feels bolder
                          weight: 700, // 👈 Material Symbols (Flutter 3.10+)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
