<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/course/modlib.php');
require_once($CFG->dirroot . '/mod/assign/lib.php');
require_once($CFG->dirroot.'/grade/grading/lib.php');
require_once($CFG->dirroot.'/grade/grading/form/rubric/lib.php');
require_once($CFG->dirroot.'/course/lib.php'); // For course functions

use external_function_parameters;
use external_single_structure;
use external_value;
use context_course;
use context_module;
use coding_exception;
use external_api;

class create_lesson_plan extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters(
            array(
                'courseid' => new external_value(PARAM_INT, 'ID of the course'),
                'lessonPlanName' => new external_value(PARAM_TEXT, 'The name of the lesson plan'),
                'content' => new external_value(PARAM_RAW, 'Manual entry content of the lesson plan'),
            )
        );
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure(
            array(
                'lessonPlanId' => new external_value(PARAM_INT, 'ID of the created lesson plan'),
            )
        );
    }

    public static function execute($courseid, $lessonPlanName, $content): array {
        global $DB, $USER;
    
        // Debugging: log the input parameters
        error_log("courseid: $courseid, lessonPlanName: $lessonPlanName, content: $content");
    
        // Validate parameters
        $params = self::validate_parameters(self::execute_parameters(), array(
            'courseid' => $courseid,
            'lessonPlanName' => $lessonPlanName,
            'content' => $content
        ));
    
        // Check user permissions for creating a lesson plan in the specified course
        $context = context_course::instance($params['courseid']);
        self::validate_context($context);
        require_capability('moodle/course:manageactivities', $context);
    
        // Add the lesson plan to the database as a new module instance
        $lessonPlan = new \stdClass();
        $lessonPlan->course = $params['courseid'];
        $lessonPlan->name = $params['lessonPlanName'];
        $lessonPlan->intro = $params['content']; // Use content for lesson plan's intro
        $lessonPlan->introformat = FORMAT_HTML;
        $lessonPlan->timecreated = time();
        $lessonPlan->timemodified = time();
    
        // Insert the lesson plan into the database
        $lessonPlanId = $DB->insert_record('lesson', $lessonPlan);
    
        if (!$lessonPlanId) {
            throw new moodle_exception('errorcreatinglesson', 'local_learninglens');
        }
    
        // Return the ID of the created lesson plan
        return array('lessonPlanId' => $lessonPlanId);
    }
    
}
