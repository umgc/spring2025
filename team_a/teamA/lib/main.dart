import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Views/assessments_view.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/notifiers/theme_notifier.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'Views/dashboard.dart';
import 'Views/essay_generation.dart';
import 'Views/quiz_generator.dart';
import 'Views/edit_questions.dart';


void main() async{
  await dotenv.load();
  // runApp(MyApp());
  await LocalStorageService.init(); // Initialize SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()), // Theme provider
        ChangeNotifierProvider(create: (_) => LoginNotifier()), // Login provider
      ],
      child: MyApp(),
    ),
  );
}

//click and drag for intuitiveness
class CustomScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

//below is an app builder, leave it here for now
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<LoginNotifier>(context);

    // used to determine which dashboard to show based on the local storage system
    var selectedClassroom = LocalStorageService.getSelectedClassroom();
    var home = selectedClassroom == LmsType.MOODLE ? TeacherDashboard() : TeacherDashboard(); //GoogleTeacherDashboard(); 
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Learning Lens",
      home:  home,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Provider.of<ThemeNotifier>(context).primaryColor),
      ),
      scrollBehavior: CustomScrollBehavior(),
      routes: {
        // '/EssayEditPage': (context) => EssayEditPage(jsonData),
        // '/Content': (context) => ViewCourseContents(),
        '/EssayGenerationPage': (context) => EssayGeneration(title: 'Essay Generation'),
        '/QuizGenerationPage': (context) => CreateAssessment(),
        '/EditQuestions': (context) => EditQuestions(''),
        // '/create': (context) => const CreatePage(),
        '/dashboard': (context) => TeacherDashboard(),
        '/user': (context) => UserSettings(),
        //'/send_essay_to_moodle': (context) => EssayAssignmentSettings(''),
        '/assessments': (context) => AssessmentsView(),
        // '/viewExams': (context) => const ViewExamPage(),
        // '/settings': (context) => Setting(themeModeNotifier: _themeModeNotifier)
      },
    );
  }
}

class DevLaunch extends StatefulWidget {
  @override
  State createState() {
    return _DevLaunch();
  }
}

class _DevLaunch extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Dev Launch Page')),
        body: Column(children: [
          ElevatedButton(
              child: const Text('dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              }),
          // ElevatedButton(
          //     child: const Text('Open Edit Essay'),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => EssayEditPage(jsonData)),
          //       );
          //     }),
          // ElevatedButton(
          //     child: const Text('Open Contents Carousel'),
          //     onPressed: () async {
          //       if (MoodleApiSingleton().isLoggedIn()){
          //         MainController().selectCourse(0);
          //       }
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => ViewCourseContents()),
          //       );
          //     }),
          ElevatedButton(
              child: const Text('Open Essay Generation'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EssayGeneration(title: 'Essay Generation')),
                );
              }),
          ElevatedButton(
              child: const Text('Teacher Dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              }),
          // ElevatedButton(
          //     child: const Text('Send essay to Moodle'),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => EssayAssignmentSettings(tempRubricXML)),
          //       );
          //     }),
          ElevatedButton(
            child: const Text('Quiz Generator'),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateAssessment()));
            },
          ),
          ElevatedButton(
            child: const Text('Edit Questions'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditQuestions('')));
            },
          ),
          ElevatedButton(
            child: const Text('View Quizzes'),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssessmentsView())
              );
            }
          )
        ]));
  }

} 