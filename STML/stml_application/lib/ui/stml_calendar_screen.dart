import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class stmlCalendarScreen extends StatelessWidget {
  const stmlCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SfCalendar(
          view: CalendarView.month,
          allowedViews: <CalendarView>
          [
            CalendarView.day,
            CalendarView.week,
            CalendarView.workWeek,
            CalendarView.month,
            CalendarView.schedule
          ],
          headerHeight: 100,
          showDatePickerButton: true,
          showTodayButton: true,
          allowViewNavigation: true,
          monthViewSettings: MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showAgenda: true,
            agendaViewHeight: 400,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.yellow,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.thumb_up, color: Colors.black),
        ),
      ),
    );
  }
}