<?php
defined('MOODLE_INTERNAL') || die();

$capabilities = array(
    'local/learninglens:createquiz' => array(
        'riskbitmask' => RISK_SPAM | RISK_XSS,

        'captype' => 'write',
        'contextlevel' => CONTEXT_COURSE,
        'archetypes' => array(
            'teacher' => CAP_ALLOW,
            'editingteacher' => CAP_ALLOW,
        ),
    ),
);