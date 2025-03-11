<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/mod/quiz/lib.php');
require_once($CFG->dirroot . '/mod/quiz/locallib.php');
require_once($CFG->libdir . '/gradelib.php');
require_once($CFG->dirroot . '/question/editlib.php');
require_once($CFG->dirroot . '/question/engine/lib.php');
require_once($CFG->dirroot . '/question/lib.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/course/modlib.php');
require_once($CFG->dirroot . '/mod/quiz/report/statistics/report.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use context_system;
use context_course;
use context_module;
use moodle_exception;
use coding_exception;
use required_capability_exception;
use access_manager;
use external_api;
use qformat_xml;
use question_bank;
use question_edit_contexts;


class create_quiz extends \external_api {

public static function execute_parameters(): external_function_parameters {
    return new external_function_parameters(
        array(
            'courseid' => new external_value(PARAM_INT, 'ID of the course'),
            'name' => new external_value(PARAM_TEXT, 'Name of the quiz'),
            'intro' => new external_value(PARAM_RAW, 'Introductory text for the quiz'),
            'sectionid' => new external_value(PARAM_INT, 'Section ID', VALUE_DEFAULT, 1),
            'timeopen'  => new external_value(PARAM_TEXT, 'Time when the quiz opens', VALUE_DEFAULT, '0'),
            'timeclose' => new external_value(PARAM_TEXT, 'Time when the quiz closes', VALUE_DEFAULT, '0'),
        )
    );
}

public static function execute_returns(): external_single_structure {
    return new external_single_structure(
        array(
            'quizid' => new external_value(PARAM_INT, 'ID of the created quiz')
        )
    );
}

public static function execute($courseid, $name, $intro, $sectionid=1, $timeopen='0', $timeclose='0'): array {
    global $DB, $USER;

    // validate params
    $params = self::validate_parameters(self::execute_parameters(), array(
        'courseid' => $courseid,
        'name' => $name,
        'intro' => $intro,
        'sectionid' => $sectionid,
        'timeopen' => $timeopen,
        'timeclose' => $timeclose
    ));

    // set context
    $context = context_course::instance($params['courseid']);

    // ensure the user has permission to create a quiz
    self::validate_context($context);
    require_capability('mod/quiz:addinstance', $context);
    require_capability('mod/quiz:manage', $context);

    // create the course module
    $module = new \stdClass();
    $module->course = $params['courseid'];
    $module->module = $DB->get_field('modules', 'id', array('name' => 'quiz'));
    $module->instance = 0;
    $module->section = $params['sectionid']; 
    $module->visible = 1;
    $module->visibleold = 1;
    $module->groupmode = 0;
    $module->groupingid = 0;
    $module->completion = 0;
    $module->idnumber = $params['sectionid'];
    $module->added = time();

    // add the course module
    $module->coursemodule = add_course_module($module);
    if (!$module->coursemodule) {
        throw new moodle_exception('Could not create course module');
    }

    // update module ID
    $module->id = $module->coursemodule;

    // add course module to section
    \course_add_cm_to_section($params['courseid'], $module->id, $params['sectionid']);


    // Convert date strings to Unix timestamps
    $timeopen = strtotime($params['timeopen']); // Convert '12 January 2024' to Unix timestamp
    $timeclose = strtotime($params['timeclose']); 

    // create the quiz module
    $quiz = new \stdClass();
    $quiz->course = $params['courseid'];
    $quiz->name = $params['name'];
    $quiz->intro = '<p>' . $params['intro'] . '</p>';
    $quiz->introformat = FORMAT_HTML;
    $quiz->timeopen = $timeopen;
    $quiz->timeclose = $timeclose;
    $quiz->preferredbehaviour = 'deferredfeedback';
    $quiz->attempts = 0;
    $quiz->grade = 100;
    $quiz->sumgrades = 1; // this get updated in the add_type_randoms_to_quiz to propertly calculate the sum based on the number of questions.
    $quiz->timelimit = 0;
    $quiz->overduehandling = 'autosubmit';
    $quiz->graceperiod = 0;
    $quiz->timecreated = time();
    $quiz->timemodified = time();
    $quiz->quizpassword = '';
    $quiz->coursemodule = $module->id;
    $quiz->feedbackboundarycount = 0;
    $quiz->feedbacktext = [];
    $quiz->questionsperpage = 1;
    $quiz->shuffleanswers = 1;
    $quiz->browsersecurity = '-';

    // process the options from the form.
    $result = quiz_process_options($quiz);
    if ($result && is_string($result)) {
        throw new moodle_exception($result);
    }

    // insert the quiz into the database
    $quiz->id = $DB->insert_record('quiz', $quiz);

    // update the course module with the quiz instance ID
    $DB->set_field('course_modules', 'instance', $quiz->id, array('id' => $module->id));

    // create the first section for this quiz.
    $DB->insert_record('quiz_sections', ['quizid' => $quiz->id, 'firstslot' => 1, 'heading' => '', 'shufflequestions' => 0]);

    // clear feedback
    $DB->delete_records('quiz_feedback', ['quizid' => $quiz->id]);

    // set feedback
    for ($i = 0; $i <= $quiz->feedbackboundarycount; $i++) {
        if (isset($quiz->feedbacktext[$i])) {
            $feedback = new \stdClass();
            $feedback->quizid = $quiz->id;
            $feedback->feedbacktext = $quiz->feedbacktext[$i]['text'] ?? '';
            $feedback->feedbacktextformat = $quiz->feedbacktext[$i]['format'] ?? FORMAT_HTML;
            $feedback->mingrade = $quiz->feedbackboundaries[$i] ?? 0;
            $feedback->maxgrade = $quiz->feedbackboundaries[$i - 1] ?? 100;
            $feedback->id = $DB->insert_record('quiz_feedback', $feedback);
            $feedbacktext = file_save_draft_area_files((int)$quiz->feedbacktext[$i]['itemid'] ?? 0,
                $context->id, 'mod_quiz', 'feedback', $feedback->id,
                ['subdirs' => false, 'maxfiles' => -1, 'maxbytes' => 0],
                $quiz->feedbacktext[$i]['text'] ?? '');
            $DB->set_field('quiz_feedback', 'feedbacktext', $feedbacktext, ['id' => $feedback->id]);
        }
    }

    // store settings belonging to the access rules
    \mod_quiz\access_manager::save_settings($quiz);

    // update  events related to this quiz
    quiz_update_events($quiz);
    $completionexpected = (!empty($quiz->completionexpected)) ? $quiz->completionexpected : null;
    \core_completion\api::update_completion_date_event($quiz->coursemodule, 'quiz', $quiz->id, $completionexpected);

    // update related grade item.
    quiz_grade_item_update($quiz);

    // update quiz review fields
    $quiz->reviewattempt = 69888;
    $quiz->reviewcorrectness = 4352;
    $quiz->reviewmaxmarks = 69888;
    $quiz->reviewmarks = 4352;
    $quiz->reviewspecificfeedback = 4352;
    $quiz->reviewgeneralfeedback = 4352;
    $quiz->reviewrightanswer = 4352;
    $quiz->reviewoverallfeedback = 4352;
    $DB->update_record('quiz', $quiz);

    // return quiz ID
    return array('quizid' => $quiz->id);
}
};