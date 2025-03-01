<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_value;
use external_api;
use context_course;

class update_lesson_plan extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'lessonid' => new external_value(PARAM_INT, 'ID of the lesson plan to update'),
            'name' => new external_value(PARAM_TEXT, 'Updated lesson plan name', VALUE_OPTIONAL),
            'intro' => new external_value(PARAM_RAW, 'Updated lesson plan description', VALUE_OPTIONAL),
            'available' => new external_value(PARAM_INT, 'Updated available timestamp', VALUE_OPTIONAL),
            'deadline' => new external_value(PARAM_INT, 'Updated deadline timestamp', VALUE_OPTIONAL),
        ]);
    }

    public static function execute($lessonid, $name = null, $intro = null, $available = null, $deadline = null) {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'lessonid' => $lessonid,
            'name' => $name,
            'intro' => $intro,
            'available' => $available,
            'deadline' => $deadline
        ]);

        // Check if the lesson plan exists
        if (!$lesson = $DB->get_record('lesson', ['id' => $lessonid], '*', IGNORE_MISSING)) {
            throw new \moodle_exception('invalidlessonid', 'error', '', $lessonid);
        }

        // Get course context
        $context = context_course::instance($lesson->course);

        // Ensure user has permission to update lesson plans
        require_capability('mod/lesson:manage', $context);

        // Prepare update data
        $updateData = ['id' => $lessonid];

        if (!is_null($name)) {
            $updateData['name'] = $name;
        }
        if (!is_null($intro)) {
            $updateData['intro'] = $intro;
        }
        if (!is_null($available)) {
            $updateData['available'] = $available;
        }
        if (!is_null($deadline)) {
            $updateData['deadline'] = $deadline;
        }

        // Perform update
        $DB->update_record('lesson', (object)$updateData);

        return ['status' => 'success', 'message' => 'Lesson plan updated successfully'];
    }

    public static function execute_returns() {
        return new external_single_structure([
            'status' => new external_value(PARAM_TEXT, 'Status of the request'),
            'message' => new external_value(PARAM_TEXT, 'Message about the operation result'),
        ]);
    }
}
