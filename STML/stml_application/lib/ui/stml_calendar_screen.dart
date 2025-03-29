import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class stmlCalendarScreen extends StatelessWidget {
  const stmlCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true,
        // Setting up the app bar at the top of the screen
        appBar: const CustomAppBar(
          title: 'Recipient Profile',
        ),
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