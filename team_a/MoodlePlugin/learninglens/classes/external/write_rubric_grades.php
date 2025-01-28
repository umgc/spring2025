<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

/**
 * Writes rubric grades for a specific submission.
 *
 * @param int $assignmentid The ID of the assignment.
 * @param int $userid The ID of the student.
 * @param string $rubricgrades The rubric grading data (as a JSON string).
 * @return bool Success or failure of the grade writing process.
 */

require_once($CFG->libdir . '/externallib.php');
require_once("$CFG->dirroot/grade/grading/lib.php");
require_once("$CFG->dirroot/mod/assign/locallib.php");
require_once($CFG->dirroot . '/grade/grading/form/rubric/lib.php');

use external_function_parameters;
use external_single_structure;
use external_value;
use context_module;
use external_api;

class write_rubric_grades extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'assignmentid' => new external_value(PARAM_INT, 'ID of the assignment'),
            'userid' => new external_value(PARAM_INT, 'ID of the user'),
            'rubricgrades' => new external_value(PARAM_RAW, 'Rubric grading data in JSON string format')
        ]);
    }

    // Define the return structure for the function.
    public static function execute_returns() {
        return new external_value(PARAM_BOOL, 'True if the rubric grades were successfully written.');
    }

    public static function execute($assignmentid, $userid, $rubricgrades, $comment = '') {
        global $DB, $USER;
    
        // Validate the parameters.
        $params = self::validate_parameters(self::execute_parameters(), [
            'assignmentid' => $assignmentid,
            'userid' => $userid,
            'rubricgrades' => $rubricgrades
        ]);
    
        // Decode the JSON string into an array.
        $rubricgrades_array = json_decode($rubricgrades, true);
    
        // Check if the JSON decoding was successful.
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \moodle_exception('invalidjson', 'error', '', json_last_error_msg());
        }
    
        // Check if there is already a record in the assign_grades table for this user and assignment.
        $grade_record = $DB->get_record('assign_grades', ['assignment' => $assignmentid, 'userid' => $userid]);
    
        // If no grade record exists, insert a new one.
        if (!$grade_record) {
            $new_grade = new \stdClass();
            $new_grade->assignment = $assignmentid;
            $new_grade->userid = $userid;
            $new_grade->grader = $USER->id;  // Set the current user as the grader.
            $new_grade->timecreated = time();
            $new_grade->timemodified = time();
            $new_grade->grade = -1;  // Initial placeholder grade (to be updated later).
            $new_grade->attemptnumber = 0;  // Assuming this is the first attempt.
            $new_grade->id = $DB->insert_record('assign_grades', $new_grade);
            $itemid = $new_grade->id;  // Use the newly inserted record's ID as the itemid.
        } else {
            // Use the existing grade record's ID as the itemid.
            $itemid = $grade_record->id;
        }
    
        // Get the course module for the assignment.
        $course_module_id = $DB->get_field('course_modules', 'id', [
            'instance' => $assignmentid,
            'module' => $DB->get_field('modules', 'id', ['name' => 'assign'])
        ]);
    
        if (!$course_module_id) {
            throw new \moodle_exception('nocoursemodule', 'error', '', 'Course module not found for assignment.');
        }
    
        // Get the assignment's grading rubric controller.
        $context = context_module::instance($course_module_id);
        $gradingmanager = get_grading_manager($context, 'mod_assign', 'submissions');
        
        // Check if the assignment is using the rubric grading method.
        if (!$gradingmanager->get_active_method() || $gradingmanager->get_active_method() !== 'rubric') {
            throw new \moodle_exception('norubriccontroller', 'error', '', 'This assignment is not using the rubric grading method.');
        }
    
        $controller = $gradingmanager->get_controller('rubric');
    
        // Check if there's already an existing grading instance for the rater and item.
        $gradinginstance = $controller->get_current_instance($USER->id, $itemid);


        if (!$gradinginstance) {
        // If no instance exists, create a new one.
            $gradinginstance = $controller->create_instance($USER->id, $itemid);
        }

        // Get the instance ID for further operations.
        $instanceid = $gradinginstance->get_data('id');
    
        // Initialize variables to calculate the total score and maximum score.
        $total_score = 0;
        $max_score = 0;
    
        // Get the rubric definition from the grading controller, which contains the criteria and levels.
        $rubricdefinition = $controller->get_definition();
        // Now get the criteria from the rubric definition.
        $rubriccriteria = $DB->get_records('gradingform_rubric_criteria', ['definitionid' => $rubricdefinition->id]);

    
        // Calculate the maximum possible score based on the full rubric definition.
        foreach ($rubriccriteria as $criterion) {
            $maxlevel = $DB->get_record_sql(
                'SELECT MAX(score) as maxscore FROM {gradingform_rubric_levels} WHERE criterionid = ?',
                [$criterion->id]
            );
            $max_score += $maxlevel->maxscore;
        }
    
        // Write rubric grades for each criterion and calculate the total score for the graded criteria.
        foreach ($rubricgrades_array as $grade) {
            // Ensure the criterion and level exist.
            $criterion = $DB->get_record('gradingform_rubric_criteria', ['id' => $grade['criterionid']], '*', MUST_EXIST);
            $level = $DB->get_record('gradingform_rubric_levels', ['id' => $grade['levelid'], 'criterionid' => $criterion->id], '*', MUST_EXIST);
    
            // Add the selected level score to the total score.
            $total_score += $level->score;
    
            // Check if there's already an entry for this instance and criterion, update or insert as necessary.
            $existinggrade = $DB->get_record('gradingform_rubric_fillings', ['instanceid' => $gradinginstance->get_data('id'), 'criterionid' => $criterion->id]);
    
            if ($existinggrade) {
                // Update existing grade.
                $existinggrade->levelid = $grade['levelid'];
                $existinggrade->remark = $grade['remark'];
                $existinggrade->raterid = $USER->id; // Assuming the current user is the rater.
                $DB->update_record('gradingform_rubric_fillings', $existinggrade);
            } else {
                // Insert new grade.
                $newgrade = new \stdClass();
                $newgrade->instanceid = $gradinginstance->get_data('id');  // Use correct instanceid
                $newgrade->criterionid = $criterion->id;
                $newgrade->levelid = $grade['levelid'];
                $newgrade->remark = $grade['remark'];
                $newgrade->raterid = $USER->id; // Assuming the current user is the rater.
                $DB->insert_record('gradingform_rubric_fillings', $newgrade);
            }
        }
    
        // Create a new object for updating the grading instance's status.
        $instanceupdate = new \stdClass();
        $instanceupdate->id = $gradinginstance->get_data('id');
        $instanceupdate->status = 1;  // 1 means "finalized".
        $DB->update_record('grading_instances', $instanceupdate); 

        // Delete any unsubmitted (status = 0) grading instances for this user and item.
        $DB->delete_records('grading_instances', ['itemid' => $itemid, 'raterid' => $USER->id, 'status' => 0]);
    
        // Get the maximum grade for the assignment
        $assignment = $DB->get_record('assign', ['id' => $assignmentid], '*', MUST_EXIST);
        $maxgrade = $assignment->grade;  // Maximum possible grade
    
        // Calculate the final grade as a proportion of the total score to the maximum possible score.
        $finalgradevalue = ($total_score / $max_score) * $maxgrade;
    
        // Update the grade in the assign_grades table to reflect the final state.
        $finalgrade = $DB->get_record('assign_grades', ['id' => $itemid], '*', MUST_EXIST);
        $finalgrade->grader = $USER->id;
        $finalgrade->grade = $finalgradevalue;
        $finalgrade->timemodified = time();
        $DB->update_record('assign_grades', $finalgrade);

        $gradeupdate = new \stdClass();
        $gradeupdate->id = $finalgrade->id;
        $gradeupdate->assignment = $assignmentid;
        $gradeupdate->userid = $userid;
        $gradeupdate->grade = $finalgradevalue;
        $gradeupdate->rawgrade = $finalgradevalue;
        $gradeupdate->grader = $USER->id;
        $gradeupdate->timecreated = $finalgrade->timecreated;
        $gradeupdate->timemodified = time();
        $assign = new \assign($context, null, null);
        $assign->update_grade($gradeupdate);
    
        return true;
    }
    
}
