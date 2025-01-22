<?php

namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/mod/quiz/locallib.php');

use context_course;
use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;
use core_question\local\bank\question_edit_contexts;
use qformat_xml;

class add_type_randoms_to_quiz extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'quizid' => new external_value(PARAM_INT, 'The quiz ID'),
            'categoryid' => new external_value(PARAM_INT, 'Question Category ID'),
            'numquestions' => new external_value(PARAM_INT, 'Number of Questions to add')
        ]);
    }

    public static function execute_returns() {
        return new external_value(PARAM_BOOL, 'Returns TRUE if succesful');

    }

    public static function execute(int $quizid, int $categoryid, int $numquestions): bool {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'quizid' => $quizid,
            'categoryid' => $categoryid,
            'numquestions' => $numquestions,
        ]);

        try {
            // Fetch the quiz object.
            $quiz = $DB->get_record('quiz', ['id' => $quizid], '*', MUST_EXIST);

            // Fetch the module context for the quiz.
            $cm = get_coursemodule_from_instance('quiz', $quizid, $quiz->course, false, MUST_EXIST);
            $context = \context_module::instance($cm->id);

            quiz_add_random_questions($quiz, $addonpage = 0, $categoryid, $numquestions, false);

            return true; // Return true on successful addition.

        } catch (Exception $e) {
            // Log the error message or handle the error as needed.
            debugging('Error adding random questions to quiz: ' . $e->getMessage());
            return false; // Return false if an error occurs.
        }
    }
}
