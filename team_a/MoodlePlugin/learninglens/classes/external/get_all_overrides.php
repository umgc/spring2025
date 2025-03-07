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
                id AS override_id,
                'quiz' AS assignment_type,
                quiz AS assignment_id,
                groupid,
                userid,
                timeopen AS start_time,
                timeclose AS end_time,
                timelimit,
                NULL AS cutoff_time,
                attempts,
                password,
                NULL AS sortorder
            FROM mdl_quiz_overrides
            UNION ALL
            SELECT
                id AS override_id,
                'essay' AS assignment_type,
                assignid AS assignment_id,
                groupid,
                userid,
                allowsubmissionsfromdate AS start_time,
                duedate AS end_time,
                timelimit,
                cutoffdate AS cutoff_time,
                NULL AS attempts,
                NULL AS password,
                sortorder
            FROM mdl_assign_overrides;
            ";

        return $DB->get_records_sql($sql);
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'override_id' => new external_value(PARAM_INT, 'Override ID'),
                'assignment_type' => new external_value(PARAM_TEXT, 'Assignment Type'),
                'assignment_id' => new external_value(PARAM_INT, 'Assignment ID'),
                'groupid' => new external_value(PARAM_INT, 'Group ID'),
                'userid' => new external_value(PARAM_INT, 'User ID'),
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
