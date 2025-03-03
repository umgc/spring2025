<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_value;
use external_api;

class add_quiz_override extends external_api {

    /**
     * Define parameters for the external function
     */
    public static function execute_parameters() {
        return new external_function_parameters([
            'quizid'    => new external_value(PARAM_INT, 'ID of the quiz'),
            'userid'    => new external_value(PARAM_INT, 'User ID (null if group override)', VALUE_DEFAULT, null),
            'groupid'   => new external_value(PARAM_INT, 'Group ID (null if user override)', VALUE_DEFAULT, null),
            'timeopen'  => new external_value(PARAM_INT, 'Time when quiz opens (null for default)', VALUE_DEFAULT, null),
            'timeclose' => new external_value(PARAM_INT, 'Time when quiz closes (null for default)', VALUE_DEFAULT, null),
            'timelimit' => new external_value(PARAM_INT, 'Quiz time limit in seconds (null for default)', VALUE_DEFAULT, null),
            'attempts'  => new external_value(PARAM_INT, 'Allowed attempts (null for default)', VALUE_DEFAULT, null),
            'password'  => new external_value(PARAM_TEXT, 'Quiz password (null for default)', VALUE_DEFAULT, null),
        ]);
    }

    /**
     * Inserts a new quiz override record
     */
    public static function execute($quizid, $userid = null, $groupid = null, $timeopen = null, $timeclose = null, $timelimit = null, $attempts = null, $password = null) {
        global $DB;

        // Validate parameters
        $params = self::validate_parameters(self::execute_parameters(), [
            'quizid'    => $quizid,
            'userid'    => $userid,
            'groupid'   => $groupid,
            'timeopen'  => $timeopen,
            'timeclose' => $timeclose,
            'timelimit' => $timelimit,
            'attempts'  => $attempts,
            'password'  => $password,
        ]);

        // Ensure either a user or group ID is provided
        if (empty($params['userid']) && empty($params['groupid'])) {
            throw new \moodle_exception('invalidoverride', 'local_learninglens', '', 'Either a userid or groupid must be provided.');
        }

        // Prepare data for insertion
        $record = new \stdClass();
        $record->quiz = $params['quizid'];
        $record->userid = $params['userid'];
        $record->groupid = $params['groupid'];
        $record->timeopen = $params['timeopen'];
        $record->timeclose = $params['timeclose'];
        $record->timelimit = $params['timelimit'];
        $record->attempts = $params['attempts'];
        $record->password = $params['password'];

        // Insert into the database
        $overrideid = $DB->insert_record('quiz_overrides', $record);

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
