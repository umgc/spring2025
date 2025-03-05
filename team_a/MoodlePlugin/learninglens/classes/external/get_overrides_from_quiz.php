<?php
namespace local_learninglens\external; // ✅ Ensure this matches services.php

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;

class get_overrides_from_quiz extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'quizid' => new external_value(PARAM_INT, 'ID of the quiz'),
        ]);
    }

    public static function execute($quizid) {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['quizid' => $quizid]);

        $questions = self::get_questions_by_quiz($quizid);

        return $questions;
    }

    private static function get_questions_by_quiz($quizid) {
        global $DB;

        $sql = "
            SELECT q.id, q.quiz, q.userid, q.timeopen, q.timeclose, q.timelimit, q.attempts, q.password
            FROM {quiz_overrides} q
            WHERE q.quiz = :quizid
            ";

        return $DB->get_records_sql($sql, ['quizid' => $quizid]);
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id' => new external_value(PARAM_INT, 'Override ID'),
                'quiz' => new external_value(PARAM_INT, 'Quiz ID'),
                'userid' => new external_value(PARAM_INT, 'User ID'),
                'timeopen' => new external_value(PARAM_INT, 'Time Open'),
                'timeclose' => new external_value(PARAM_INT, 'Time Close'),
                'timelimit' => new external_value(PARAM_INT, 'Time Limit'),
                'attempts' => new external_value(PARAM_INT, 'Attempts'),
                'password' => new external_value(PARAM_TEXT, 'Student Password'),
            ])
        );
    }
}
