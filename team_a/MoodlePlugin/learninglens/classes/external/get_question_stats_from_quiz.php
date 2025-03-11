<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;

class get_question_stats_from_quiz extends external_api {

    /**
     * Define parameter structure for the function.
     */
    public static function execute_parameters() {
        return new external_function_parameters([
            'quizid' => new external_value(PARAM_INT, 'ID of the quiz'),
        ]);
    }

    /**
     * Main execution function. This is what gets called by the web service.
     */
    public static function execute($quizid) {
        // Validate incoming parameters.
        $params = self::validate_parameters(
            self::execute_parameters(),
            ['quizid' => $quizid]
        );

        // *Optional*: permission checks (capabilities, context, etc.)

        // Actually fetch data.
        $records = self::get_question_stats_by_quiz($params['quizid']);

        // Return the array of data.
        return $records;
    }

    /**
     * The real logic. Query for questions (similar to your existing logic)
     * but also compute correct/incorrect stats or any other analytics.
     */
    private static function get_question_stats_by_quiz($quizid) {
        global $DB;
    
        // 1) Gather the questions (same as before)
        $sql_questions = "
            SELECT q.id,
                   q.name,
                   q.questiontext,
                   q.qtype
              FROM {question} q
             WHERE q.id IN (
                SELECT qbe.id
                  FROM {question_bank_entries} qbe
                 WHERE qbe.questioncategoryid = (
                    SELECT qc.id
                      FROM {question_categories} qc
                     WHERE (
                         SELECT quiz.intro
                           FROM {quiz} quiz
                          WHERE quiz.id = :quizid
                     ) LIKE CONCAT('%', qc.name, '%')
                     LIMIT 1
                 )
             )
        ";
    
        $questions = $DB->get_records_sql($sql_questions, ['quizid' => $quizid]);
        if (!$questions) {
            return [];
        }
    
        // 2) Gather attempt stats by looking for 'gradedright', 'gradedwrong', 'gradedpartial'
        //    instead of 'complete' or fraction-based checks
        $sql_stats = "
            SELECT
                qa.questionid,
                SUM(CASE WHEN qs.state = 'gradedright'   THEN 1 ELSE 0 END) AS numcorrect,
                SUM(CASE WHEN qs.state = 'gradedwrong'   THEN 1 ELSE 0 END) AS numincorrect,
                SUM(CASE WHEN qs.state = 'gradedpartial' THEN 1 ELSE 0 END) AS numpartial,
                COUNT(*) AS totalattempts
              FROM {quiz_attempts} quiza
              JOIN {question_usages} qu ON qu.id = quiza.uniqueid
              JOIN {question_attempts} qa ON qa.questionusageid = qu.id
              JOIN {question_attempt_steps} qs ON qs.questionattemptid = qa.id
                   AND qs.sequencenumber = (
                       SELECT MAX(qs2.sequencenumber)
                         FROM {question_attempt_steps} qs2
                        WHERE qs2.questionattemptid = qa.id
                   )
             WHERE quiza.quiz = :quizid2
          GROUP BY qa.questionid
        ";
    
        $statsrecords = $DB->get_records_sql($sql_stats, ['quizid2' => $quizid]);
    
        // 3) Merge stats with the question array
        $results = [];
        foreach ($questions as $q) {
            $qid = $q->id;
    
            // Default zeros
            $correct   = 0;
            $incorrect = 0;
            $partial   = 0;
            $total     = 0;
    
            if (isset($statsrecords[$qid])) {
                $record    = $statsrecords[$qid];
                $correct   = (int) $record->numcorrect;
                $incorrect = (int) $record->numincorrect;
                $partial   = (int) $record->numpartial;
                $total     = (int) $record->totalattempts;
            }
    
            $results[] = [
                'id'           => $qid,
                'name'         => $q->name,
                'questiontext' => $q->questiontext,
                'qtype'        => $q->qtype,
                'numcorrect'   => $correct,
                'numincorrect' => $incorrect,
                'numpartial'   => $partial,
                'totalattempts'=> $total,
            ];
        }
    
        return $results;
    }
    

    /**
     * Define the return structure.
     */
    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id'            => new external_value(PARAM_INT, 'Question ID'),
                'name'          => new external_value(PARAM_TEXT, 'Question name'),
                'questiontext'  => new external_value(PARAM_RAW, 'Question text'),
                'qtype'         => new external_value(PARAM_ALPHANUMEXT, 'Question type'),
                'numcorrect'    => new external_value(PARAM_INT, 'Number of fully correct attempts'),
                'numincorrect'  => new external_value(PARAM_INT, 'Number of fully incorrect attempts'),
                'numpartial'    => new external_value(PARAM_INT, 'Number of partially correct attempts'),
                'totalattempts' => new external_value(PARAM_INT, 'Total attempts (final steps)'),
            ])
        );
    }
    
}
