<?php
namespace local_learninglens\external; // ✅ Ensure this matches services.php

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;

class get_questions_from_quiz extends external_api {

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
            SELECT q.id, q.name, q.questiontext, q.qtype
            FROM {question} q
            WHERE q.id IN (
                SELECT qbe.id
                FROM {question_bank_entries} qbe
                WHERE qbe.questioncategoryid = (
                    SELECT qc.id
                    FROM {question_categories} qc
                    WHERE (
                        SELECT quiz.intro
                        FROM {quiz} quiz
                        WHERE quiz.id = :quizid
                    ) LIKE CONCAT('%', qc.name, '%')
                    LIMIT 1
                )
            )";

        return $DB->get_records_sql($sql, ['quizid' => $quizid]);
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id' => new external_value(PARAM_INT, 'Question ID'),
                'name' => new external_value(PARAM_TEXT, 'Question name'),
                'questiontext' => new external_value(PARAM_RAW, 'Question text'),
                'qtype' => new external_value(PARAM_ALPHANUMEXT, 'Question type'),
            ])
        );
    }
}
