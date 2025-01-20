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

class create_assignment extends external_api {

    // Define the input parameters for the web service
    public static function execute_parameters() {
        return new external_function_parameters(
            array(
                'courseid'        => new external_value(PARAM_INT, 'Course ID'),
                'sectionid'       => new external_value(PARAM_INT, 'Section ID'),
                'assignmentName'  => new external_value(PARAM_TEXT, 'Assignment name'),
                'startdate'       => new external_value(PARAM_TEXT, 'Start date (timestamp)'),
                'enddate'         => new external_value(PARAM_TEXT, 'End date (timestamp)'),
                'rubricJson'      => new external_value(PARAM_RAW, 'Rubric JSON', VALUE_DEFAULT, ''),
                'description'     => new external_value(PARAM_RAW, 'Assignment description', VALUE_DEFAULT, '')
            )
        );
    }

    // The actual function that performs the task
    public static function execute($courseid, $sectionid, $assignmentName, $startdate, $enddate, $rubricJson = '', $description = '') {
        global $USER, $DB;

        // Validate the parameters
        $params = self::validate_parameters(
            self::execute_parameters(),
            array(
                'courseid'        => $courseid,
                'sectionid'       => $sectionid,
                'assignmentName'  => $assignmentName,
                'startdate'       => $startdate,
                'enddate'         => $enddate,
                'rubricJson'      => $rubricJson,
                'description'     => $description
            )
        );

    // Convert date strings to timestamps
    $startdate_timestamp = strtotime($startdate);
    $enddate_timestamp = strtotime($enddate);

    // Validate the conversion
    if ($startdate_timestamp === false) {
        throw new invalid_parameter_exception('Invalid start date format.');
    }
    if ($enddate_timestamp === false) {
        throw new invalid_parameter_exception('Invalid end date format.');
    }

        // Capability check
        $context = context_course::instance($courseid);
        require_capability('mod/assign:addinstance', $context);

        // Prepare the course module data
        $moduleid = $DB->get_field('modules', 'id', ['name' => 'assign']);
        $cm = new \stdClass();
        $cm->course = $courseid;
        $cm->module = $moduleid;
        $cm->section = $sectionid;
        $cm->visible = 1;

        // Add the course module entry
        $cmid = add_course_module($cm);

        // Prepare the assignment data
        $assignment_data = new \stdClass();
        $assignment_data->course = $courseid;
        $assignment_data->name = $assignmentName;
        $assignment_data->intro = $description;
        $assignment_data->introformat = FORMAT_HTML;
        $assignment_data->duedate = $enddate_timestamp;
        $assignment_data->allowsubmissionsfromdate = $startdate_timestamp;
        $assignment_data->grade = 100;
        $assignment_data->coursemodule = $cmid;

        // Required fields that must be set
        $assignment_data->submissiondrafts = 0; // Allow submission drafts: 0 = No, 1 = Yes
        $assignment_data->requiresubmissionstatement = 0; // Require submission statement
        $assignment_data->sendnotifications = 1; // Send notifications to graders
        $assignment_data->sendlatenotifications = 1; // Send notifications about late submissions
        $assignment_data->sendstudentnotifications = 1; // Notify students
        $assignment_data->teamsubmission = 0; // Team submissions
        $assignment_data->requireallteammemberssubmit = 0; // Require all team members to submit
        $assignment_data->blindmarking = 0; // Blind marking
        $assignment_data->attemptreopenmethod = 'none'; // Attempt reopen method: 'none', 'manual', 'untilpass'
        $assignment_data->maxattempts = -1; // Max attempts (-1 for unlimited)
        $assignment_data->markingworkflow = 0; // Marking workflow
        $assignment_data->markingallocation = 0; // Marking allocation
        $assignment_data->cutoffdate = $enddate_timestamp; // Cut-off date
        $assignment_data->gradingduedate = 0; // Grading due date
        $assignment_data->grade = 100; // Maximum grade
        $assignment_data->completionsubmit = 0; // Completion tracking
        $assignment_data->alwaysshowdescription = 1; // Always show description

        // Initialize submission plugin settings
        $assignment_data->assignsubmission_onlinetext_enabled = 1; // Enable online text submissions
        $assignment_data->assignsubmission_file_enabled = 0;       // Disable file submissions

        // Create the assignment instance
        $assignment_instance = assign_add_instance($assignment_data);

        // Update the course module with the correct instance ID
        $DB->set_field('course_modules', 'instance', $assignment_instance, ['id' => $cmid]);

        // Add the course module to the section
        course_add_cm_to_section($courseid, $cmid, $sectionid);

        // Set the assignment to use advanced grading (rubric) if rubricJson is provided
        if (!empty($rubricJson)) {
            // Create the context_module object
            $module_context = context_module::instance($cmid);

            require_capability('moodle/grade:managegradingforms', $module_context);

            // Initialize the grading manager
            $grading_manager = get_grading_manager($module_context);
            $grading_manager->set_area('submissions');
            $grading_manager->set_component('mod_assign');
            $grading_manager->set_active_method('rubric');

            // Get the controller for the 'rubric' grading method
            $rubric_controller = $grading_manager->get_controller('rubric');

            // Create the rubric definition using the custom function
            $rubric_definition = self::create_rubric_definition_from_json($rubricJson);

            $rubric_controller->update_definition($rubric_definition);
            $rubricid = $rubric_controller->get_definition()->id;
        }

        return array('assignmentid' => $assignment_instance, 'assignmentname' => $assignmentName, 'rubricid' => $rubricid);
    }

    public static function execute_returns() {
        return new external_single_structure(
            array(
                'assignmentid'   => new external_value(PARAM_INT, 'Assignment ID'),
                'assignmentname' => new external_value(PARAM_TEXT, 'Assignment name'),
                'rubricid' => new external_value(PARAM_TEXT, 'Rubric ID')
            )
        );
    }

    public static function create_rubric_definition_from_json($rubricJson) {
        // Decode the JSON input into an associative array
        $rubric_data = json_decode($rubricJson, true);

        // Check if the JSON is valid
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new coding_exception('Invalid JSON format.');
        }

        // Validate that the required fields (criteria and levels) exist in the JSON
        if (!isset($rubric_data['criteria']) || !is_array($rubric_data['criteria'])) {
            throw new coding_exception('Invalid rubric format: missing criteria.');
        }

        // Initialize the rubric definition object (stdClass)
        $rubric_definition = new \stdClass();
        $rubric_definition->status = 20; // 20 represents 'active'
        $rubric_definition->description = ''; // Optional: Add rubric description if needed
        $rubric_definition->name = 'Rubric Name'; // Optional: Set the rubric name

        // Initialize the 'rubric' property with 'criteria' and 'options'
        $rubric_definition->rubric = array(
            'criteria' => array(),
            'options' => array(
                'sortlevelsasc' => 1,
                'allowscoreoverrides' => 0,
                'showdescriptionteacher' => 1,
                'showdescriptionstudent' => 0,
                // Add other options as required
            ),
        );

        // Variables to keep track of criterion and level IDs
        $criterion_id = 0;
        $level_id = 0;

        // Loop through each criterion in the JSON data
        foreach ($rubric_data['criteria'] as $criterion_data) {
            // Each criterion will be an associative array with 'levels' as an array
            $criterion_array = array();
            $criterion_array['id'] = $criterion_id;
            $criterion_array['description'] = $criterion_data['description'];
            $criterion_array['sortorder'] = $criterion_id; // Sort order starts at 0
            $criterion_array['levels'] = array();

            // Validate that the levels field exists
            if (!isset($criterion_data['levels']) || !is_array($criterion_data['levels'])) {
                throw new coding_exception('Invalid rubric format: missing levels for criterion.');
            }

            // Level counter for keys
            $level_key = 0;

            // Loop through each level in the criterion
            foreach ($criterion_data['levels'] as $level_data) {
                // Each level is an associative array with a definition (name) and score (points)
                $level_array = array();
                $level_array['id'] = $level_id; // ID is integer
                $level_array['definition'] = $level_data['definition'];
                $level_array['score'] = $level_data['score'];

                // Assign the level array to the criterion's levels array with 'NEWID' keys
                // This is required for the update_definition method to see them as new levels
                $criterion_array['levels']['NEWID' . $level_key] = $level_array;

                $level_id++;
                $level_key++;
            }

            // Assign the criterion array to the rubric_definition's rubric['criteria'] array with 'NEWID' keys
            $rubric_definition->rubric['criteria']['NEWID' . $criterion_id] = $criterion_array;
            $criterion_id++;
        }

        // Add the description_editor property
        $rubric_definition->description_editor = array(
            'text' => $rubric_definition->description,
            'format' => FORMAT_HTML,
        );

        return $rubric_definition;
    }
}
