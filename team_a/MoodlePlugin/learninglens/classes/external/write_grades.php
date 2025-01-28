<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

/**
 * Writes grades for a specific submission.
 *
 * @param int $assignmentid The ID of the assignment.
 * @param int $userid The ID of the student.
 * @param string $rubricgrades The rubric grading data (as a JSON string).
 * @return bool Success or failure of the grade writing process.
 */

require_once($CFG->libdir . '/externallib.php');
require_once("$CFG->dirroot/grade/grading/lib.php");
require_once("$CFG->dirroot/mod/assign/locallib.php");

use external_function_parameters;
use external_single_structure;
use external_value;
use context_module;
use external_api;

class write_grades extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'assignmentid' => new external_value(PARAM_INT, 'ID of the assignment'),
            'userid' => new external_value(PARAM_INT, 'ID of the user'),
            'grade' => new external_value(PARAM_INT, 'Raw grade value')
        ]);
    }

    // Define the return structure for the function.
    public static function execute_returns() {
        return new external_value(PARAM_BOOL, 'True if the grades were successfully written.');
    }

    public static function execute($assignmentid, $userid, $grade, $comment = '') {
        global $DB, $USER;
    
        // Validate the parameters.
        $params = self::validate_parameters(self::execute_parameters(), [
            'assignmentid' => $assignmentid,
            'userid' => $userid,
            'grade' => $grade
        ]);
    
    
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



        // Update the grade in the assign_grades table to reflect the final state.
        $finalgrade = $DB->get_record('assign_grades', ['id' => $itemid], '*', MUST_EXIST);
        $finalgrade->grader = $USER->id;
        $finalgrade->grade = $grade;
        $finalgrade->timemodified = time();
        $DB->update_record('assign_grades', $finalgrade);


        $gradeupdate = new \stdClass();
        $gradeupdate->id = $finalgrade->id;
        $gradeupdate->assignment = $assignmentid;
        $gradeupdate->userid = $userid;
        $gradeupdate->grade = $grade;
        $gradeupdate->rawgrade = $grade;
        $gradeupdate->grader = $USER->id;
        $gradeupdate->timecreated = $finalgrade->timecreated;
        $gradeupdate->timemodified = time();
        $assign = new \assign($context, null, null);
        $assign->update_grade($gradeupdate);
    
        return true;
    }
    
}
