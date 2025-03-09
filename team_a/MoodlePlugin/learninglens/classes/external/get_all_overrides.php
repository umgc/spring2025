<?php
namespace local_learninglens\external; // ✅ Ensure this matches services.php

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;

class get_all_overrides extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([]);
    }

    public static function execute() {
        global $DB;

        $questions = self::get_overrides();

        return $questions;
    }

    private static function get_overrides() {
        global $DB;

        $sql = "
            SELECT
                qo.id AS override_id,
                'quiz' AS assignment_type,
                qo.quiz AS assignment_id,
                q.name AS assignment_name,
                q.course AS course_id,
                c.fullname AS course_name,
                qo.userid,
                CONCAT(u.firstname, ' ', u.lastname) AS fullname,
                qo.timeopen AS start_time,
                qo.timeclose AS end_time,
                qo.timelimit,
                NULL AS cutoff_time,
                qo.attempts,
                qo.password,
                NULL AS sortorder
            FROM mdl_quiz_overrides qo
            LEFT JOIN mdl_quiz q ON qo.quiz = q.id
            LEFT JOIN mdl_course c ON q.course = c.id
            LEFT JOIN mdl_user u ON qo.userid = u.id
            UNION ALL
            SELECT
                ao.id AS override_id,
                'essay' AS assignment_type,
                ao.assignid AS assignment_id,
                a.name AS assignment_name,
                a.course AS course_id,
                c.fullname AS course_name,
                ao.userid,
                CONCAT(u.firstname, ' ', u.lastname) AS fullname,
                ao.allowsubmissionsfromdate AS start_time,
                ao.duedate AS end_time,
                ao.timelimit,
                ao.cutoffdate AS cutoff_time,
                NULL AS attempts,
                NULL AS password,
                ao.sortorder
            FROM mdl_assign_overrides ao
            LEFT JOIN mdl_assign a ON ao.assignid = a.id
            LEFT JOIN mdl_course c ON a.course = c.id
            LEFT JOIN mdl_user u ON ao.userid = u.id;
            ";

        return $DB->get_records_sql($sql);
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'override_id' => new external_value(PARAM_INT, 'Override ID'),
                'assignment_type' => new external_value(PARAM_TEXT, 'Assignment Type'),
                'assignment_id' => new external_value(PARAM_INT, 'Assignment ID'),
                'assignment_name' => new external_value(PARAM_TEXT, 'Assignment Name'),
                'course_id' => new external_value(PARAM_INT, 'Course ID'),
                'course_name' => new external_value(PARAM_TEXT, 'Course Name'),
                'userid' => new external_value(PARAM_INT, 'User ID'),
                'fullname' => new external_value(PARAM_TEXT, 'Full name'),
                'start_time' => new external_value(PARAM_INT, 'Time Open'),
                'end_time' => new external_value(PARAM_INT, 'Time Close'),
                'timelimit' => new external_value(PARAM_INT, 'Time Limit'),
                'cutoff_time' => new external_value(PARAM_INT, 'Cutoff Time (Essay only)'),
                'attempts' => new external_value(PARAM_INT, 'Attempts (Quiz only)'),
                'password' => new external_value(PARAM_TEXT, 'Password (Quiz only)'),
                'sortorder' => new external_value(PARAM_INT, 'Sortorder (Essay only)'),
            ])
        );
    }
}
