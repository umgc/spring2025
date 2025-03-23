<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_value;
use external_api;
use context_module;
use context_course;

class delete_lesson_plan extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'lessonid' => new external_value(PARAM_INT, 'ID of the lesson plan to delete'),
        ]);
    }

    public static function execute($lessonid) {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['lessonid' => $lessonid]);

        // Check if the lesson plan exists
        if (!$lesson = $DB->get_record('lesson', ['id' => $lessonid], '*', IGNORE_MISSING)) {
            throw new \moodle_exception('invalidlessonid', 'error', '', $lessonid);
        }

        // Get course context
        $context = context_course::instance($lesson->course);

        // Ensure user has permission to delete lesson plans
        require_capability('mod/lesson:manage', $context);

        // Delete the lesson plan
        $DB->delete_records('lesson', ['id' => $lessonid]);
        
        // Clear cache for the lesson plan
        purge_all_caches();

        return ['status' => 'success', 'message' => 'Lesson plan deleted successfully'];
    }

    public static function execute_returns() {
        return new external_single_structure([
            'status' => new external_value(PARAM_TEXT, 'Status of the request'),
            'message' => new external_value(PARAM_TEXT, 'Message about the operation result'),
        ]);
    }
}
