<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/mod/lesson/lib.php');
require_once($CFG->dirroot . '/course/lib.php'); // For rebuild_course_cache

use external_function_parameters;
use external_single_structure;
use external_value;
use context_course;
use moodle_exception;
use external_api;
use stdClass;

/**
 * Create a lesson and link it to the course module.
 * Allows for advanced configuration (password, showdescription, completion, etc.).
 */
class create_lesson extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT,  'Course ID in which to create the lesson'),
            'name'     => new external_value(PARAM_TEXT, 'Lesson name/title'),

            'intro'         => new external_value(PARAM_RAW,  'Lesson description/intro',  VALUE_OPTIONAL, ''),
            'introformat'   => new external_value(PARAM_INT,  'Intro format (1=HTML, 0=MOODLE, etc.)', VALUE_OPTIONAL, FORMAT_HTML),

            // Visibility of intro on course page
            'showdescription' => new external_value(
                PARAM_INT,
                'Display description on course page? (1=yes,0=no)',
                VALUE_OPTIONAL,
                1 // default to showing description
            ),

            // Lesson availability fields
            'available' => new external_value(
                PARAM_INT,
                'Timestamp when the lesson opens (defaults to now if 0)',
                VALUE_OPTIONAL,
                0
            ),
            'deadline' => new external_value(
                PARAM_INT,
                'Timestamp for lesson deadline (0=no deadline)',
                VALUE_OPTIONAL,
                0
            ),
            'timelimit' => new external_value(
                PARAM_INT,
                'Time limit (seconds). 0 means no limit',
                VALUE_OPTIONAL,
                0
            ),

            // Attempts/retakes
            'retake' => new external_value(
                PARAM_INT,
                'Allow retakes? (1=yes,0=no)',
                VALUE_OPTIONAL,
                1
            ),
            'maxattempts' => new external_value(
                PARAM_INT,
                'Maximum number of attempts allowed',
                VALUE_OPTIONAL,
                3
            ),

            // Lesson password
            'usepassword' => new external_value(
                PARAM_INT,
                '1 if a password is required, 0 otherwise',
                VALUE_OPTIONAL,
                0
            ),
            'password' => new external_value(
                PARAM_RAW,
                'Lesson password if usepassword=1',
                VALUE_OPTIONAL,
                ''
            ),

            // Activity completion in course_modules
            'completion' => new external_value(
                PARAM_INT,
                'Enable completion tracking? (1=yes,0=no)',
                VALUE_OPTIONAL,
                1
            ),
        ]);
    }

    public static function execute(
        $courseid,
        $name,
        $intro = '',
        $introformat = FORMAT_HTML,
        $showdescription = 1,

        $available = 0,
        $deadline = 0,
        $timelimit = 0,

        $retake = 1,
        $maxattempts = 3,

        $usepassword = 0,
        $password = '',

        $completion = 1
    ) {
        global $DB;

        // 1. Validate parameters
        $params = self::validate_parameters(
            self::execute_parameters(),
            [
                'courseid'        => $courseid,
                'name'            => $name,
                'intro'           => $intro,
                'introformat'     => $introformat,
                'showdescription' => $showdescription,
                'available'       => $available,
                'deadline'        => $deadline,
                'timelimit'       => $timelimit,
                'retake'          => $retake,
                'maxattempts'     => $maxattempts,
                'usepassword'     => $usepassword,
                'password'        => $password,
                'completion'      => $completion
            ]
        );

        // 2. Check if course exists
        if (!$DB->record_exists('course', ['id' => $params['courseid']])) {
            throw new moodle_exception('invalidcourseid', 'error', '', $params['courseid']);
        }

        // 3. Validate context/capability
        $context = context_course::instance($params['courseid']);
        self::validate_context($context);
        require_capability('mod/lesson:addinstance', $context);

        // 4. Create lesson record
        $lesson = new stdClass();
        $lesson->course       = $params['courseid'];
        $lesson->name         = $params['name'];
        $lesson->intro        = $params['intro'];
        $lesson->introformat  = $params['introformat'];

        // If 'available' is 0, we can default to now => time()
        $lesson->available    = ($params['available'] == 0) ? time() : $params['available'];

        $lesson->deadline     = $params['deadline'];
        $lesson->timelimit    = $params['timelimit'];
        $lesson->retake       = $params['retake'];
        $lesson->maxattempts  = $params['maxattempts'];

        // Lesson password usage
        $lesson->usepassword  = $params['usepassword']; // field typically in lesson table
        $lesson->password     = $params['password'];

        $lesson->timecreated  = time();
        $lesson->timemodified = time();

        // If your version of Moodle requires conditions => store empty JSON
        $lesson->conditions = '[]';

        // Insert into mdl_lesson
        $lessonid = $DB->insert_record('lesson', $lesson);
        if (!$lessonid) {
            throw new moodle_exception('errorcreatinglesson', 'local_learninglens');
        }

        // 5. Link lesson to the course modules
        // 5a. Get module ID for 'lesson'
        $module = $DB->get_record('modules', ['name' => 'lesson'], 'id');
        if (!$module) {
            throw new moodle_exception('modulenotfound', 'error');
        }

        // 5b. Find default course section (assuming section=1)
        $section = $DB->get_record('course_sections', [
            'course'  => $params['courseid'],
            'section' => 1
        ], 'id,sequence');

        if (!$section) {
            throw new moodle_exception('sectionnotfound', 'error');
        }

        // 5c. Insert a record in mdl_course_modules
        $cm = new stdClass();
        $cm->course         = $params['courseid'];
        $cm->module         = $module->id;
        $cm->instance       = $lessonid;
        $cm->section        = $section->id;
        $cm->added          = time();
        $cm->visible        = 1;  // show the lesson
        $cm->visibleold     = 1;
        $cm->groupmode      = 0;
        $cm->groupingid     = 0;

        // Activity completion
        $cm->completion     = $params['completion'];

        // "Display description on course page"
        $cm->showdescription = $params['showdescription'];

        $courseModuleId = $DB->insert_record('course_modules', $cm);
        if (!$courseModuleId) {
            throw new moodle_exception('erroraddingmodule', 'local_learninglens');
        }

        // 5d. Update the course section sequence
        $sequence = trim($section->sequence . ',' . $courseModuleId, ',');
        $section->sequence = $sequence;
        $DB->update_record('course_sections', $section);

        // 6. Rebuild cache
        rebuild_course_cache($params['courseid'], true);

        // 7. Return lessonId + courseModuleId
        return [
            'lessonId'       => $lessonid,
            'courseModuleId' => $courseModuleId,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'lessonId' => new external_value(
                PARAM_INT, 'ID of the newly created lesson'
            ),
            'courseModuleId' => new external_value(
                PARAM_INT, 'ID of the newly inserted course module record'
            ),
        ]);
    }
}
