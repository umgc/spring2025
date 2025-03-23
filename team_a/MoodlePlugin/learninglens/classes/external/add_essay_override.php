<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_value;
use external_api;

class add_essay_override extends external_api {

    /**
     * Define parameters for the external function
     */
    public static function execute_parameters() {
        return new external_function_parameters([
            'assignid'    => new external_value(PARAM_INT, 'ID of the essay'),
            'userid'    => new external_value(PARAM_INT, 'User ID (null if group override)', VALUE_DEFAULT, null),
            'groupid'   => new external_value(PARAM_INT, 'Group ID (null if user override)', VALUE_DEFAULT, null),
            'allowsubmissionsfromdate'  => new external_value(PARAM_INT, 'Time when essay opens (null for default)', VALUE_DEFAULT, null),
            'duedate' => new external_value(PARAM_INT, 'Time when essay closes (null for default)', VALUE_DEFAULT, null),
            'cutoffdate' => new external_value(PARAM_INT, 'Time when essay submission is no longer allowed (null for default)', VALUE_DEFAULT, null),
            'timelimit'  => new external_value(PARAM_INT, 'Essay time limit in seconds (null for default)', VALUE_DEFAULT, null),
            'sortorder'  => new external_value(PARAM_INT, 'Essay sort order (null for default)', VALUE_DEFAULT, null),
        ]);
    }

    /**
     * Inserts a new quiz override record
     */
    public static function execute($assignid, $userid = null, $groupid = null, $allowsubmissionsfromdate = null, $duedate = null, $cutoffdate = null, $timelimit = null, $sortorder = null) {
        global $DB;

        // Validate parameters
        $params = self::validate_parameters(self::execute_parameters(), [
            'assignid'    => $assignid,
            'userid'    => $userid,
            'groupid'   => $groupid,
            'allowsubmissionsfromdate'  => $allowsubmissionsfromdate,
            'duedate' => $duedate,
            'cutoffdate' => $cutoffdate,
            'timelimit'  => $timelimit,
            'sortorder'  => $sortorder,
        ]);

        // Ensure either a user or group ID is provided
        if (empty($params['userid']) && empty($params['groupid'])) {
            throw new \moodle_exception('invalidoverride', 'local_learninglens', '', 'Either a userid or groupid must be provided.');
        }

        // Prepare data for insertion
        $record = new \stdClass();
        $record->assignid = $params['assignid'];
        $record->userid = $params['userid'];
        $record->groupid = $params['groupid'];
        $record->allowsubmissionsfromdate = $params['allowsubmissionsfromdate'];
        $record->duedate = $params['duedate'];
        $record->cutoffdate = $params['cutoffdate'];
        $record->timelimit = $params['timelimit'];
        $record->sortorder = $params['sortorder'];

        // Insert into the database
        $overrideid = $DB->insert_record('assign_overrides', $record);

        // Return the inserted override ID
        return ['overrideid' => $overrideid];
    }

    /**
     * Defines the return structure
     */
    public static function execute_returns() {
        return new external_single_structure([
            'overrideid' => new external_value(PARAM_INT, 'ID of the created quiz override'),
        ]);
    }
}
