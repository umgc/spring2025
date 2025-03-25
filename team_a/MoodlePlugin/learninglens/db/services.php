<?php
namespace learninglens\db;

$functions = [
    'local_learninglens_create_quiz' => [
        'classname' => 'local_learninglens\external\create_quiz',
        'description' => 'Create a quiz in a specified course',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'mod/quiz:addinstance',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],

    'local_learninglens_import_questions' => [
        'classname' => 'local_learninglens\external\import_questions',
        'description' => 'Import XML questions to a course question bank',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'moodle/question:add',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_add_type_randoms_to_quiz' => [
        'classname' => 'local_learninglens\external\add_type_randoms_to_quiz',
        'description' => 'Add questions of type random to quiz from category',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'mod/quiz:manage',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_get_rubric' => [
        'classname' => 'local_learninglens\external\get_rubric',
        'description' => 'Returns instances of grading forms including rubrics.',
        'type' => 'read',
        'ajax' => true,
        'capabilities' => 'moodle/grade:view',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_create_assignment' => [
        'classname' => 'local_learninglens\external\create_assignment',
        'description' => 'Creates an assignment and optionally attach a rubric.',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'moodle/course:manageactivities',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_get_rubric_grades' => [
        'classname' => 'local_learninglens\external\get_rubric_grades',
        'description' => 'Gets rubric grades for a specific submission.',
        'type' => 'read',
        'ajax' => true,
        'capabilities' => 'mod/assign:grade',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_write_rubric_grades' => [
        'classname' => 'local_learninglens\external\write_rubric_grades',
        'description' => 'Sets rubric grades for a specific submission.',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'mod/assign:grade',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_write_grades' => [
        'classname' => 'local_learninglens\external\write_grades',
        'description' => 'Sets grades for a specific submission.',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'mod/assign:grade',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_create_lesson' => [
        'classname' => 'local_learninglens\external\create_lesson',
        'description' => 'Creates a new lesson in a Moodle course and links it to the course modules',
        'type' => 'write',
        'ajax' => true,
        'capabilities' => 'mod/lesson:addinstance',
        'services' => [
            MOODLE_OFFICIAL_MOBILE_SERVICE,
        ]
    ],
    'local_learninglens_get_questions_from_quiz' => [
        'classname'   => 'local_learninglens\external\get_questions_from_quiz',
        'description' => 'Fetches questions linked to a quiz ID',
        'type'        => 'read',
        'ajax'        => true,
        'capabilities'=> 'mod/quiz:view',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
    'local_learninglens_add_quiz_override' => [
        'classname'   => 'local_learninglens\external\add_quiz_override',
        'description' => 'Adds an override to a quiz for a user or group.',
        'type'        => 'write',
        'ajax'        => true,
        'capabilities'=> 'mod/quiz:manage',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
    'local_learninglens_add_essay_override' => [
        'classname'   => 'local_learninglens\external\add_essay_override',
        'description' => 'Adds an override to a essay for a user or group.',
        'type'        => 'write',
        'ajax'        => true,
        'capabilities'=> 'mod/assign:manage',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
    'local_learninglens_get_lesson_plans_by_course' => [
        'classname'   => 'local_learninglens\external\get_lesson_plans_by_course',
        'description' => 'Retrieves lesson plans associated with a given course ID.',
        'type'        => 'read',
        'ajax'        => true,
        'capabilities' => 'mod/lesson:view',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE] // Enables use in the Moodle Mobile App
    ],
    'local_learninglens_delete_lesson_plan' => [
        'classname'   => 'local_learninglens\external\delete_lesson_plan',
        'description' => 'Deletes a lesson plan by ID.',
        'type'        => 'write',
        'ajax'        => true,
        'capabilities' => 'mod/lesson:manage',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE]
    ],
    'local_learninglens_update_lesson_plan' => [
        'classname'   => 'local_learninglens\external\update_lesson_plan',
        'description' => 'Updates an existing lesson plan by ID.',
        'type'        => 'write',
        'ajax'        => true,
        'capabilities' => 'mod/lesson:manage',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE]
    ],
    'local_learninglens_get_all_overrides' => [
        'classname'   => 'local_learninglens\external\get_all_overrides',
        'description' => 'Gets overrides for both quiz and essay',
        'type'        => 'read',
        'ajax'        => true,
        'capabilities' => 'mod/quiz:view, mod/assign:view',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE]
    ],
    'local_learninglens_get_question_stats_from_quiz' => [
        'classname'   => 'local_learninglens\external\get_question_stats_from_quiz',
        'description' => 'Fetches questions + stats (correct/incorrect counts) for a quiz',
        'type'        => 'read',
        'ajax'        => true,
        'capabilities'=> 'mod/quiz:view',
        'services'    => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
];