<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once("$CFG->dirroot/grade/grading/lib.php");
require_once("$CFG->dirroot/mod/assign/locallib.php");

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use context_module;
use external_api;

class get_rubric extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'assignmentid' => new external_value(PARAM_INT, 'ID of the assignment'),
        ]);
    }

    public static function execute($assignmentid) {
        global $USER;

        // Validate the parameters.
        $params = self::validate_parameters(self::execute_parameters(), [
            'assignmentid' => $assignmentid,
        ]);

        // Fetch the definition ID for the given assignment.
        // $definitionid = self::get_definitionid_from_assignmentid($assignmentid);
        $rubricdata[] = self::get_definitionid_from_assignmentid($assignmentid);
        return $rubricdata;
    }

    public static function get_definitionid_from_assignmentid($assignmentid) {
        global $DB;

        //Get the course module ID (`cmid`) for the assignment.
        $cmid = $DB->get_field_sql("
            SELECT cm.id
            FROM {course_modules} cm
            JOIN {modules} m ON m.id = cm.module
            JOIN {assign} a ON a.id = cm.instance
            WHERE m.name = 'assign' AND a.id = ?", [$assignmentid]);

        if (!$cmid) {
            throw new \moodle_exception('invalidassignmentid', 'error', '', $assignmentid);
        }

        //Fetch the context of the assignment using the `cmid`.
        $context = context_module::instance($cmid);

        //Identify the component. For assignments, it is usually 'mod_assign'.
        $component = 'mod_assign';

        //Initialize the grading manager without context first.
        $gradingmanager = new \grading_manager();
        $gradingmanager->set_context($context);
        $gradingmanager->set_component($component);

        //Get available grading areas for the specified component and context.
        $areas = $gradingmanager->get_available_areas();
        if (!in_array('submissions', array_keys($areas))) {
            return null; // 'submissions' grading area not found.
        }
        $gradingmanager->set_area('submissions');

        //Get the controller for the 'submissions' grading area.
        $controller = $gradingmanager->get_controller('rubric');

        //Check if the grading method is 'rubric' and get the definition ID.
        if (!is_null($controller)) {
            return $controller->get_definition();
        }
        return null;
    }

    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id' => new external_value(PARAM_INT, 'Instance ID'),
                'rubric_criteria' => new external_multiple_structure(
                    new external_single_structure([
                        'id' => new external_value(PARAM_INT, 'Criterion ID'),
                        'description' => new external_value(PARAM_TEXT, 'Criterion description'),
                        'levels' => new external_multiple_structure(
                            new external_single_structure([
                                'id' => new external_value(PARAM_INT, 'Level ID'),
                                'score' => new external_value(PARAM_FLOAT, 'Level score'),
                                'definition' => new external_value(PARAM_TEXT, 'Level definition'),
                            ])
                        ),
                    ])
                ),
            ])
        );
    }
}
