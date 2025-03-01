<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;
use context_course;

class get_lesson_plans_by_course extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'ID of the course'),
        ]);
    }

    public static function execute($courseid) {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['courseid' => $courseid]);

        // Ensure course exists
        if (!$DB->record_exists('course', ['id' => $courseid])) {
            throw new \moodle_exception('invalidcourseid', 'error', '', $courseid);
        }

        // Ensure user has the correct capability to view lessons
        $context = context_course::instance($courseid);
        require_capability('mod/lesson:view', $context);

        // Fetch lesson plans
        $lessonplans = self::get_lessons_by_course($courseid);

        return array_values($lessonplans);
    }

    private static function get_lessons_by_course($courseid) {
        global $DB;

        $sql = "
            SELECT id, name, intro, timemodified
            FROM {lesson}
            WHERE course = :courseid
        ";

        return $DB->get_records_sql($sql, ['courseid' => $courseid]);
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id' => new external_value(PARAM_INT, 'Lesson Plan ID'),
                'name' => new external_value(PARAM_TEXT, 'Lesson Plan Name'),
                'intro' => new external_value(PARAM_RAW, 'Lesson Plan Description'),
                'timemodified' => new external_value(PARAM_INT, 'Last Modified Timestamp'),
            ])
        );
    }
}
