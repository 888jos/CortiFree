//
//  StringKeys.swift
//  CortiFree
//
//  Centralized localization keys for the entire app
//  Optimized for type-safe, easy-to-use localization
//  Created by Claude on 17/11/2025.
//

import Foundation

// MARK: - Localization Keys Structure
// Organized by screen/feature for easy maintenance
// Usage: Text(StringKeys.Common.close) instead of Text(NSLocalizedString("common.close", comment: ""))

struct StringKeys {

    // MARK: - Common
    struct Common {
        static var defaultUserName: String { "common.default_user_name".localized() }
        static var defaultUser: String { "common.default_user".localized() }
        static var close: String { "common.close".localized() }
        static var cancel: String { "common.cancel".localized() }
        static var validate: String { "common.validate".localized() }
        static var skip: String { "common.skip".localized() }
        static var start: String { "common.start".localized() }
        static var stop: String { "common.stop".localized() }
        static var pause: String { "common.pause".localized() }
        static var resume: String { "common.resume".localized() }
        static var continueButton: String { "common.continue".localized() }
        static var next: String { "common.next".localized() }
        static var previous: String { "common.previous".localized() }
        static var day: String { "common.day".localized() }
        static var days: String { "common.days".localized() }
        static var week: String { "common.week".localized() }
        static var weeks: String { "common.weeks".localized() }
        static var hour: String { "common.hour".localized() }
        static var hours: String { "common.hours".localized() }
        static var minute: String { "common.minute".localized() }
        static var minutes: String { "common.minutes".localized() }
        static var second: String { "common.second".localized() }
        static var seconds: String { "common.seconds".localized() }
        static var seeMore: String { "common.see_more".localized() }
        static var seeLess: String { "common.see_less".localized() }
        static var score: String { "common.score".localized() }
        static var streak: String { "common.streak".localized() }
        static var global: String { "common.global".localized() }
        static var current: String { "common.current".localized() }
        static var potential: String { "common.potential".localized() }
        static var serenity: String { "common.serenity".localized() }
        static var sleep: String { "common.sleep".localized() }
        static var energy: String { "common.energy".localized() }
        static var focus: String { "common.focus".localized() }
        static var balance: String { "common.balance".localized() }
    }

    // MARK: - Tab Bar
    struct TabBar {
        static var home: String { "tab.home".localized() }
        static var plan: String { "tab.plan".localized() }
        static var library: String { "tab.library".localized() }
        static var profile: String { "tab.profile".localized() }
    }

    // MARK: - Onboarding
    struct Onboarding {

        // MARK: Overall Quiz
        struct OverallQuiz {
            static var title: String { "onboarding.overall_quiz.title".localized() }
            static var firstNameLabel: String { "onboarding.overall_quiz.first_name_label".localized() }
            static var firstNamePlaceholder: String { "onboarding.overall_quiz.first_name_placeholder".localized() }
            static var ageLabel: String { "onboarding.overall_quiz.age_label".localized() }
            static var genderLabel: String { "onboarding.overall_quiz.gender_label".localized() }
            static var stressReasonLabel: String { "onboarding.overall_quiz.stress_reason_label".localized() }
            static var stressDurationLabel: String { "onboarding.overall_quiz.stress_duration_label".localized() }

            // Age options
            static var age1824: String { "onboarding.overall_quiz.age_18_24".localized() }
            static var age2534: String { "onboarding.overall_quiz.age_25_34".localized() }
            static var age3544: String { "onboarding.overall_quiz.age_35_44".localized() }
            static var age4554: String { "onboarding.overall_quiz.age_45_54".localized() }
            static var age55Plus: String { "onboarding.overall_quiz.age_55_plus".localized() }

            // Gender options
            static var genderMale: String { "onboarding.overall_quiz.gender_male".localized() }
            static var genderFemale: String { "onboarding.overall_quiz.gender_female".localized() }
            static var genderOther: String { "onboarding.overall_quiz.gender_other".localized() }
            static var genderPreferNot: String { "onboarding.overall_quiz.gender_prefer_not".localized() }

            // Stress reasons
            static var reasonWork: String { "onboarding.overall_quiz.reason_work".localized() }
            static var reasonFinances: String { "onboarding.overall_quiz.reason_finances".localized() }
            static var reasonRelationships: String { "onboarding.overall_quiz.reason_relationships".localized() }
            static var reasonHealth: String { "onboarding.overall_quiz.reason_health".localized() }
            static var reasonFamily: String { "onboarding.overall_quiz.reason_family".localized() }
            static var reasonStudies: String { "onboarding.overall_quiz.reason_studies".localized() }
            static var reasonFuture: String { "onboarding.overall_quiz.reason_future".localized() }
            static var reasonOther: String { "onboarding.overall_quiz.reason_other".localized() }

            // Duration options
            static var durationLessThan1Month: String { "onboarding.overall_quiz.duration_less_1_month".localized() }
            static var duration13Months: String { "onboarding.overall_quiz.duration_1_3_months".localized() }
            static var duration36Months: String { "onboarding.overall_quiz.duration_3_6_months".localized() }
            static var duration612Months: String { "onboarding.overall_quiz.duration_6_12_months".localized() }
            static var durationMoreThan1Year: String { "onboarding.overall_quiz.duration_more_1_year".localized() }
        }

        // MARK: Habits Quiz
        struct HabitsQuiz {
            static var title: String { "onboarding.habits_quiz.title".localized() }
            static var subtitle: String { "onboarding.habits_quiz.subtitle".localized() }
            static var questionOf: String { "onboarding.habits_quiz.question_of".localized() }

            // Questions
            static var q1: String { "onboarding.habits_quiz.q1".localized() }
            static var q2: String { "onboarding.habits_quiz.q2".localized() }
            static var q3: String { "onboarding.habits_quiz.q3".localized() }
            static var q4: String { "onboarding.habits_quiz.q4".localized() }
            static var q5: String { "onboarding.habits_quiz.q5".localized() }
            static var q6: String { "onboarding.habits_quiz.q6".localized() }
            static var q7: String { "onboarding.habits_quiz.q7".localized() }
            static var q8: String { "onboarding.habits_quiz.q8".localized() }
            static var q9: String { "onboarding.habits_quiz.q9".localized() }
            static var q10: String { "onboarding.habits_quiz.q10".localized() }
            static var q11: String { "onboarding.habits_quiz.q11".localized() }
            static var q12: String { "onboarding.habits_quiz.q12".localized() }

            // Answer options (generic)
            static var never: String { "onboarding.habits_quiz.answer_never".localized() }
            static var rarely: String { "onboarding.habits_quiz.answer_rarely".localized() }
            static var sometimes: String { "onboarding.habits_quiz.answer_sometimes".localized() }
            static var often: String { "onboarding.habits_quiz.answer_often".localized() }
            static var always: String { "onboarding.habits_quiz.answer_always".localized() }
        }

        // MARK: Rating View
        struct Rating {
            static var currentTitle: String { "onboarding.rating.current_title".localized() }
            static var potentialTitle: String { "onboarding.rating.potential_title".localized() }
            static var potentialSubtitle: String { "onboarding.rating.potential_subtitle".localized() }
            static var seePotential: String { "onboarding.rating.see_potential".localized() }
        }

        // MARK: Eight Habits Intro
        struct EightHabitsIntro {
            static var title: String { "onboarding.eight_habits_intro.title".localized() }
            static var subtitle: String { "onboarding.eight_habits_intro.subtitle".localized() }
            static var habitMeditation: String { "onboarding.eight_habits_intro.habit_meditation".localized() }
            static var habitBreathing: String { "onboarding.eight_habits_intro.habit_breathing".localized() }
            static var habitJournal: String { "onboarding.eight_habits_intro.habit_journal".localized() }
            static var habitSport: String { "onboarding.eight_habits_intro.habit_sport".localized() }
            static var habitWater: String { "onboarding.eight_habits_intro.habit_water".localized() }
            static var habitNature: String { "onboarding.eight_habits_intro.habit_nature".localized() }
            static var habitSleep: String { "onboarding.eight_habits_intro.habit_sleep".localized() }
            static var habitSocial: String { "onboarding.eight_habits_intro.habit_social".localized() }
        }

        // MARK: Eight Habits Flow
        struct EightHabitsFlow {
            static var seeDetails: String { "onboarding.eight_habits_flow.see_details".localized() }
            static var howHabitsHelp: String { "onboarding.eight_habits_flow.how_habits_help".localized() }

            // Meditation
            static var meditationTitle: String { "onboarding.eight_habits_flow.meditation_title".localized() }
            static var meditationSubtitle: String { "onboarding.eight_habits_flow.meditation_subtitle".localized() }
            static var meditationBenefit1: String { "onboarding.eight_habits_flow.meditation_benefit_1".localized() }
            static var meditationBenefit2: String { "onboarding.eight_habits_flow.meditation_benefit_2".localized() }
            static var meditationBenefit3: String { "onboarding.eight_habits_flow.meditation_benefit_3".localized() }
            static var meditationImpactSerenity: String { "onboarding.eight_habits_flow.meditation_impact_serenity".localized() }
            static var meditationImpactFocus: String { "onboarding.eight_habits_flow.meditation_impact_focus".localized() }
            static var meditationImpactBalance: String { "onboarding.eight_habits_flow.meditation_impact_balance".localized() }

            // Breathing
            static var breathingTitle: String { "onboarding.eight_habits_flow.breathing_title".localized() }
            static var breathingSubtitle: String { "onboarding.eight_habits_flow.breathing_subtitle".localized() }
            static var breathingBenefit1: String { "onboarding.eight_habits_flow.breathing_benefit_1".localized() }
            static var breathingBenefit2: String { "onboarding.eight_habits_flow.breathing_benefit_2".localized() }
            static var breathingBenefit3: String { "onboarding.eight_habits_flow.breathing_benefit_3".localized() }
            static var breathingImpactSerenity: String { "onboarding.eight_habits_flow.breathing_impact_serenity".localized() }
            static var breathingImpactEnergy: String { "onboarding.eight_habits_flow.breathing_impact_energy".localized() }

            // Journal
            static var journalTitle: String { "onboarding.eight_habits_flow.journal_title".localized() }
            static var journalSubtitle: String { "onboarding.eight_habits_flow.journal_subtitle".localized() }
            static var journalBenefit1: String { "onboarding.eight_habits_flow.journal_benefit_1".localized() }
            static var journalBenefit2: String { "onboarding.eight_habits_flow.journal_benefit_2".localized() }
            static var journalBenefit3: String { "onboarding.eight_habits_flow.journal_benefit_3".localized() }
            static var journalImpactSerenity: String { "onboarding.eight_habits_flow.journal_impact_serenity".localized() }
            static var journalImpactBalance: String { "onboarding.eight_habits_flow.journal_impact_balance".localized() }

            // Sport
            static var sportTitle: String { "onboarding.eight_habits_flow.sport_title".localized() }
            static var sportSubtitle: String { "onboarding.eight_habits_flow.sport_subtitle".localized() }
            static var sportBenefit1: String { "onboarding.eight_habits_flow.sport_benefit_1".localized() }
            static var sportBenefit2: String { "onboarding.eight_habits_flow.sport_benefit_2".localized() }
            static var sportBenefit3: String { "onboarding.eight_habits_flow.sport_benefit_3".localized() }
            static var sportImpactEnergy: String { "onboarding.eight_habits_flow.sport_impact_energy".localized() }
            static var sportImpactSleep: String { "onboarding.eight_habits_flow.sport_impact_sleep".localized() }
            static var sportImpactBalance: String { "onboarding.eight_habits_flow.sport_impact_balance".localized() }

            // Water
            static var waterTitle: String { "onboarding.eight_habits_flow.water_title".localized() }
            static var waterSubtitle: String { "onboarding.eight_habits_flow.water_subtitle".localized() }
            static var waterBenefit1: String { "onboarding.eight_habits_flow.water_benefit_1".localized() }
            static var waterBenefit2: String { "onboarding.eight_habits_flow.water_benefit_2".localized() }
            static var waterBenefit3: String { "onboarding.eight_habits_flow.water_benefit_3".localized() }
            static var waterImpactEnergy: String { "onboarding.eight_habits_flow.water_impact_energy".localized() }
            static var waterImpactFocus: String { "onboarding.eight_habits_flow.water_impact_focus".localized() }

            // Nature
            static var natureTitle: String { "onboarding.eight_habits_flow.nature_title".localized() }
            static var natureSubtitle: String { "onboarding.eight_habits_flow.nature_subtitle".localized() }
            static var natureBenefit1: String { "onboarding.eight_habits_flow.nature_benefit_1".localized() }
            static var natureBenefit2: String { "onboarding.eight_habits_flow.nature_benefit_2".localized() }
            static var natureBenefit3: String { "onboarding.eight_habits_flow.nature_benefit_3".localized() }
            static var natureImpactSerenity: String { "onboarding.eight_habits_flow.nature_impact_serenity".localized() }
            static var natureImpactBalance: String { "onboarding.eight_habits_flow.nature_impact_balance".localized() }

            // Sleep
            static var sleepTitle: String { "onboarding.eight_habits_flow.sleep_title".localized() }
            static var sleepSubtitle: String { "onboarding.eight_habits_flow.sleep_subtitle".localized() }
            static var sleepBenefit1: String { "onboarding.eight_habits_flow.sleep_benefit_1".localized() }
            static var sleepBenefit2: String { "onboarding.eight_habits_flow.sleep_benefit_2".localized() }
            static var sleepBenefit3: String { "onboarding.eight_habits_flow.sleep_benefit_3".localized() }
            static var sleepImpactSleep: String { "onboarding.eight_habits_flow.sleep_impact_sleep".localized() }
            static var sleepImpactEnergy: String { "onboarding.eight_habits_flow.sleep_impact_energy".localized() }
            static var sleepImpactFocus: String { "onboarding.eight_habits_flow.sleep_impact_focus".localized() }

            // Social
            static var socialTitle: String { "onboarding.eight_habits_flow.social_title".localized() }
            static var socialSubtitle: String { "onboarding.eight_habits_flow.social_subtitle".localized() }
            static var socialBenefit1: String { "onboarding.eight_habits_flow.social_benefit_1".localized() }
            static var socialBenefit2: String { "onboarding.eight_habits_flow.social_benefit_2".localized() }
            static var socialBenefit3: String { "onboarding.eight_habits_flow.social_benefit_3".localized() }
            static var socialImpactSerenity: String { "onboarding.eight_habits_flow.social_impact_serenity".localized() }
            static var socialImpactBalance: String { "onboarding.eight_habits_flow.social_impact_balance".localized() }

            // Common
            static var benefitsTitle: String { "onboarding.eight_habits_flow.benefits_title".localized() }
            static var impactOnTitle: String { "onboarding.eight_habits_flow.impact_on_title".localized() }
        }

        // MARK: Week Progress
        struct WeekProgress {
            static var weekNumber: String { "onboarding.week_progress.week_number".localized() }
            static var week1Message: String { "onboarding.week_progress.week_1_message".localized() }
            static var week5Message: String { "onboarding.week_progress.week_5_message".localized() }
            static var week10Message: String { "onboarding.week_progress.week_10_message".localized() }
        }

        // MARK: Habits Progress Flow
        struct HabitsProgressFlow {
            static var title: String { "onboarding.habits_progress_flow.title".localized() }
            static var subtitle: String { "onboarding.habits_progress_flow.subtitle".localized() }
            static var weekLabel: String { "onboarding.habits_progress_flow.week_label".localized() }
            static var progressLabel: String { "onboarding.habits_progress_flow.progress_label".localized() }
        }

        // MARK: Social Proof - Testimonials
        struct Testimonials {
            static var title: String { "onboarding.testimonials.title".localized() }
            static var subtitle: String { "onboarding.testimonials.subtitle".localized() }

            static var testimonial1Name: String { "onboarding.testimonials.testimonial_1_name".localized() }
            static var testimonial1Age: String { "onboarding.testimonials.testimonial_1_age".localized() }
            static var testimonial1Text: String { "onboarding.testimonials.testimonial_1_text".localized() }

            static var testimonial2Name: String { "onboarding.testimonials.testimonial_2_name".localized() }
            static var testimonial2Age: String { "onboarding.testimonials.testimonial_2_age".localized() }
            static var testimonial2Text: String { "onboarding.testimonials.testimonial_2_text".localized() }

            static var testimonial3Name: String { "onboarding.testimonials.testimonial_3_name".localized() }
            static var testimonial3Age: String { "onboarding.testimonials.testimonial_3_age".localized() }
            static var testimonial3Text: String { "onboarding.testimonials.testimonial_3_text".localized() }

            static var testimonial4Name: String { "onboarding.testimonials.testimonial_4_name".localized() }
            static var testimonial4Age: String { "onboarding.testimonials.testimonial_4_age".localized() }
            static var testimonial4Text: String { "onboarding.testimonials.testimonial_4_text".localized() }
        }

        // MARK: Social Proof - Goals Selection
        struct GoalsSelection {
            static var title: String { "onboarding.goals_selection.title".localized() }
            static var subtitle: String { "onboarding.goals_selection.subtitle".localized() }

            static var goal1: String { "onboarding.goals_selection.goal_1".localized() }
            static var goal2: String { "onboarding.goals_selection.goal_2".localized() }
            static var goal3: String { "onboarding.goals_selection.goal_3".localized() }
            static var goal4: String { "onboarding.goals_selection.goal_4".localized() }
            static var goal5: String { "onboarding.goals_selection.goal_5".localized() }
            static var goal6: String { "onboarding.goals_selection.goal_6".localized() }
            static var goal7: String { "onboarding.goals_selection.goal_7".localized() }
            static var goal8: String { "onboarding.goals_selection.goal_8".localized() }

            static var selectionCount: String { "onboarding.goals_selection.selection_count".localized() }
        }

        // MARK: Authentication
        struct Authentication {
            static var title: String { "onboarding.auth.title".localized() }
            static var subtitle: String { "onboarding.auth.subtitle".localized() }
            static var emailPlaceholder: String { "onboarding.auth.email_placeholder".localized() }
            static var passwordPlaceholder: String { "onboarding.auth.password_placeholder".localized() }
            static var signInButton: String { "onboarding.auth.sign_in_button".localized() }
            static var signUpButton: String { "onboarding.auth.sign_up_button".localized() }
            static var orContinueWith: String { "onboarding.auth.or_continue_with".localized() }
            static var googleButton: String { "onboarding.auth.google_button".localized() }
            static var appleButton: String { "onboarding.auth.apple_button".localized() }
            static var alreadyHaveAccount: String { "onboarding.auth.already_have_account".localized() }
            static var noAccountYet: String { "onboarding.auth.no_account_yet".localized() }
            static var forgotPassword: String { "onboarding.auth.forgot_password".localized() }
            static var resetPassword: String { "onboarding.auth.reset_password".localized() }
            static var backToLogin: String { "onboarding.auth.back_to_login".localized() }
        }
    }

    // MARK: - Home Screen
    struct Home {
        static var congratulations: String { "home.congratulations".localized() }
        static var programStarted: String { "home.program_started".localized() }
        static var keepShining: String { "home.keep_shining".localized() }
        static var routineCountdown: String { "home.routine_countdown".localized() }
        static var antiStressButton: String { "home.antistress_button".localized() }
        static var breatheDeeply: String { "home.breathe_deeply".localized() }
        static var breatheIn: String { "home.breathe_in".localized() }
        static var breatheOut: String { "home.breathe_out".localized() }
        static var neuroplasticity: String { "home.neuroplasticity".localized() }
        static var neuroplasticityDesc: String { "home.neuroplasticity_desc".localized() }
        static var why66Days: String { "home.why_66_days".localized() }
        static var why66DaysDesc: String { "home.why_66_days_desc".localized() }
        static var scientificEvidence: String { "home.scientific_evidence".localized() }
        static var scientificEvidenceDesc: String { "home.scientific_evidence_desc".localized() }
    }

    // MARK: - Levels
    struct Levels {
        static var beginnerSerene: String { "level.beginner_serene".localized() }
        static var noviceCalm: String { "level.novice_calm".localized() }
        static var apprenticeZen: String { "level.apprentice_zen".localized() }
        static var practitionerAwakened: String { "level.practitioner_awakened".localized() }
        static var confirmedMeditator: String { "level.confirmed_meditator".localized() }
        static var expertCalm: String { "level.expert_calm".localized() }
        static var masterCalm: String { "level.master_calm".localized() }
        static var peacefulGuru: String { "level.peaceful_guru".localized() }
        static var enlightenedSage: String { "level.enlightened_sage".localized() }
        static var immortalLegend: String { "level.immortal_legend".localized() }
        static var supremeMaster: String { "level.supreme_master".localized() }
        static var novice: String { "level.novice".localized() }
    }

    // MARK: - Library Screen
    struct Library {
        static var title: String { "library.title".localized() }

        // Categories
        static var learn: String { "library.category.learn".localized() }
        static var blog: String { "library.category.blog".localized() }
        static var tips: String { "library.category.tips".localized() }
        static var studies: String { "library.category.studies".localized() }

        // Sections
        static var relaxingSounds: String { "library.relaxing_sounds".localized() }
        static var relaxingSoundsDesc: String { "library.relaxing_sounds_desc".localized() }
        static var breathingExercises: String { "library.breathing_exercises".localized() }
        static var breathingExercisesDesc: String { "library.breathing_exercises_desc".localized() }
        static var meditationExercises: String { "library.meditation_exercises".localized() }
        static var meditationExercisesDesc: String { "library.meditation_exercises_desc".localized() }

        // Sound Names
        static var soundRain: String { "library.sound.rain".localized() }
        static var soundOcean: String { "library.sound.ocean".localized() }
        static var soundFire: String { "library.sound.fire".localized() }
        static var soundWhiteNoise: String { "library.sound.white_noise".localized() }
        static var soundMorning: String { "library.sound.morning".localized() }
        static var soundForest: String { "library.sound.forest".localized() }
        static var soundStream: String { "library.sound.stream".localized() }
        static var soundSummerNight: String { "library.sound.summer_night".localized() }

        // Header sections (LibraryHeaderView)
        static var respiration: String { "library.section.respiration".localized() }
        static var meditation: String { "library.section.meditation".localized() }
        static var journal: String { "library.section.journal".localized() }
        static var research: String { "library.section.research".localized() }
    }

    // MARK: - Profile Screen
    struct Profile {
        static var scoreCortiFree: String { "profile.score_cortifree".localized() }
        static var habits: String { "profile.habits".localized() }
        static var dayProgress: String { "profile.day_progress".localized() }

        // Habit Names
        static var habitMeditation: String { "profile.habit.meditation".localized() }
        static var habitBreathing: String { "profile.habit.breathing".localized() }
        static var habitJournal: String { "profile.habit.journal".localized() }
        static var habitSport: String { "profile.habit.sport".localized() }
        static var habitWater: String { "profile.habit.water".localized() }
        static var habitNature: String { "profile.habit.nature".localized() }
        static var habitSleep: String { "profile.habit.sleep".localized() }
        static var habitSocial: String { "profile.habit.social".localized() }

        // Domain Names
        static var domainSerenity: String { "profile.domain.serenity".localized() }
        static var domainSleep: String { "profile.domain.sleep".localized() }
        static var domainEnergy: String { "profile.domain.energy".localized() }
        static var domainFocus: String { "profile.domain.focus".localized() }
        static var domainBalance: String { "profile.domain.balance".localized() }

        // Edit Profile
        static var editTitle: String { "profile.edit.title".localized() }
        static var save: String { "profile.edit.save".localized() }
        static var personalInfo: String { "profile.edit.personal_info".localized() }
        static var firstName: String { "profile.edit.first_name".localized() }
        static var sleepSection: String { "profile.edit.sleep_section".localized() }
        static var bedTime: String { "profile.edit.bed_time".localized() }
        static var wakeTime: String { "profile.edit.wake_time".localized() }
        static var goalsSection: String { "profile.edit.goals_section".localized() }
        static var currentSection: String { "profile.edit.current_section".localized() }
        static var frequencyLabel: String { "profile.edit.frequency_label".localized() }
        static var durationLabel: String { "profile.edit.duration_label".localized() }
        static var quantityLabel: String { "profile.edit.quantity_label".localized() }
        static var applyNextWeek: String { "profile.edit.apply_next_week".localized() }
        static var frequencyDaily: String { "profile.habit.frequency.daily".localized() }
        static var frequencyWeek: String { "profile.habit.frequency.week".localized() }
        static var timesPerWeek: String { "profile.habit.times_per_week".localized() }
        static var minutesPerSession: String { "profile.habit.minutes_per_session".localized() }
        static var litersPerDay: String { "profile.habit.liters_per_day".localized() }
        static var hoursPerNight: String { "profile.habit.hours_per_night".localized() }
        static var routineDuration: String { "profile.habit.routine_duration".localized() }
        static var completionRate: String { "profile.habit.completion_rate".localized() }
        static var noDataYet: String { "profile.habit.no_data_yet".localized() }
    }

    // MARK: - Tasks Screen
    struct Tasks {
        static var todo: String { "tasks.todo".localized() }
        static var done: String { "tasks.done".localized() }
        static var skipped: String { "tasks.skipped".localized() }
        static var dayProgress: String { "tasks.day_progress".localized() }
        static var encouragement: String { "tasks.encouragement".localized() }

        // Task Titles
        static var breathConsciously: String { "tasks.breathe_consciously".localized() }
        static var meditateMindfully: String { "tasks.meditate_mindfully".localized() }
        static var drinkWater: String { "tasks.drink_water".localized() }
        static var writeThoughts: String { "tasks.write_thoughts".localized() }
        static var doSport: String { "tasks.do_sport".localized() }
        static var goOutside: String { "tasks.go_outside".localized() }
        static var goodSleep: String { "tasks.good_sleep".localized() }
        static var socialTime: String { "tasks.social_time".localized() }
    }

    // MARK: - Settings Screen
    struct Settings {
        static var title: String { "settings.title".localized() }
        static var language: String { "settings.language".localized() }
        static var chooseLanguage: String { "settings.choose_language".localized() }
        static var languageSubtitle: String { "settings.language_subtitle".localized() }
        static var languageRestartNote: String { "settings.language_restart_note".localized() }

        // Profile & Objective
        static var profileObjective: String { "settings.profile_objective".localized() }
        static var currentObjective: String { "settings.current_objective".localized() }
        static var notificationsToggle: String { "settings.notifications_toggle".localized() }

        // Experience & Habits
        static var experienceHabits: String { "settings.experience_habits".localized() }
        static var morningRoutine: String { "settings.morning_routine".localized() }
        static var afternoonRoutine: String { "settings.afternoon_routine".localized() }
        static var eveningRoutine: String { "settings.evening_routine".localized() }
        static var reminderTimes: String { "settings.reminder_times".localized() }
        static var soundSettings: String { "settings.sound_settings".localized() }
        static var defaultSound: String { "settings.default_sound".localized() }
        static var voiceGuidance: String { "settings.voice_guidance".localized() }
        static var ambientVolume: String { "settings.ambient_volume".localized() }

        // Subscription
        static var subscription: String { "settings.subscription".localized() }
        static var subscriptionPremium: String { "settings.subscription_premium".localized() }
        static var subscriptionFree: String { "settings.subscription_free".localized() }
        static var renewalDate: String { "settings.renewal_date".localized() }
        static var manageSubscription: String { "settings.manage_subscription".localized() }
        static var restorePurchases: String { "settings.restore_purchases".localized() }

        // Privacy & Security
        static var privacySecurity: String { "settings.privacy_security".localized() }
        static var localDataSize: String { "settings.local_data_size".localized() }
        static var icloudSync: String { "settings.icloud_sync".localized() }
        static var syncStatus: String { "settings.sync_status".localized() }
        static var lastSync: String { "settings.last_sync".localized() }
        static var syncing: String { "settings.syncing".localized() }

        // Alerts
        static var logout: String { "settings.logout".localized() }
        static var logoutConfirm: String { "settings.logout_confirm".localized() }
        static var deleteAccount: String { "settings.delete_account".localized() }
        static var deleteAccountWarning: String { "settings.delete_account_warning".localized() }
        static var deleteAccountSuccess: String { "settings.delete_account_success".localized() }

        // Routine
        static var changeRoutine: String { "settings.change_routine".localized() }
        static var selectNewRoutine: String { "settings.select_new_routine".localized() }
        static var warningTitle: String { "settings.warning_title".localized() }
        static var changeRoutineWarning: String { "settings.change_routine_warning".localized() }

        // Sections
        static var notifications: String { "settings.notifications".localized() }
        static var sounds: String { "settings.sounds".localized() }
        static var privacy: String { "settings.privacy".localized() }
        static var about: String { "settings.about".localized() }
        static var aboutSupport: String { "settings.about_support".localized() }
        static var help: String { "settings.help".localized() }
        static var version: String { "settings.version".localized() }
        static var terms: String { "settings.terms".localized() }
        static var privacyPolicy: String { "settings.privacy_policy".localized() }
        static var contactSupport: String { "settings.contact_support".localized() }
        static var faq: String { "settings.faq".localized() }
        static var rateApp: String { "settings.rate_app".localized() }
        static var followUs: String { "settings.follow_us".localized() }

        // Debug
        static var debug: String { "settings.debug".localized() }
        static var resetDefaults: String { "settings.reset_defaults".localized() }
        static var clearAllData: String { "settings.clear_all_data".localized() }
        static var forceSync: String { "settings.force_sync".localized() }
    }

    // MARK: - Exercise Detail
    struct Exercise {
        static var start: String { "exercise.start".localized() }
        static var stop: String { "exercise.stop".localized() }
        static var pause: String { "exercise.pause".localized() }
        static var resume: String { "exercise.resume".localized() }
        static var completed: String { "exercise.completed".localized() }
        static var duration: String { "exercise.duration".localized() }
        static var description: String { "exercise.description".localized() }
        static var benefits: String { "exercise.benefits".localized() }
        static var howTo: String { "exercise.how_to".localized() }
    }

    // MARK: - Journal
    struct Journal {
        static var title: String { "journal.title".localized() }
        static var streak: String { "journal.streak".localized() }
        static var create: String { "journal.create".localized() }
        static var save: String { "journal.save".localized() }
        static var saved: String { "journal.saved".localized() }
        static var delete: String { "journal.delete".localized() }
        static var deleteConfirm: String { "journal.delete_confirm".localized() }
        static var history: String { "journal.history".localized() }

        // Tabs
        static var gratitude: String { "journal.tab.gratitude".localized() }
        static var reflection: String { "journal.tab.reflection".localized() }
        static var goals: String { "journal.tab.goals".localized() }

        // Tab Descriptions
        static var gratitudeDesc: String { "journal.desc.gratitude".localized() }
        static var reflectionDesc: String { "journal.desc.reflection".localized() }
        static var goalsDesc: String { "journal.desc.goals".localized() }

        // Sheet Titles
        static var gratitudeTitle: String { "journal.title.gratitude".localized() }
        static var reflectionTitle: String { "journal.title.reflection".localized() }
        static var goalsTitle: String { "journal.title.goals".localized() }

        // Stats
        static var thisWeek: String { "journal.stats.this_week".localized() }
        static var averageMood: String { "journal.stats.average_mood".localized() }
        static var totalEntries: String { "journal.stats.total_entries".localized() }
        static var wordCount: String { "journal.stats.word_count".localized() }
        static var words: String { "journal.stats.words".localized() }

        // Empty States
        static var noEntries: String { "journal.empty.no_entries".localized() }
        static var startWriting: String { "journal.empty.start_writing".localized() }

        // Prompts
        static var promptPlaceholder: String { "journal.prompt.placeholder".localized() }
        static var gratitudePlaceholder: String { "journal.prompt.gratitude".localized() }

        // Mood
        static var moodQuestion: String { "journal.mood.question".localized() }
        static var moodHide: String { "journal.mood.hide".localized() }
        static var moodChange: String { "journal.mood.change".localized() }
    }

    // MARK: - Habit Titles (TasksV2View)
    struct HabitTitles {
        static var sleep: String { "habit.title.sleep".localized() }
        static var breathing: String { "habit.title.breathing".localized() }
        static var meditation: String { "habit.title.meditation".localized() }
        static var water: String { "habit.title.water".localized() }
        static var sport: String { "habit.title.sport".localized() }
        static var nature: String { "habit.title.nature".localized() }
        static var social: String { "habit.title.social".localized() }
        static var journal: String { "habit.title.journal".localized() }

        // Helper function to get title by habit ID
        static func title(for habitId: String) -> String {
            switch habitId {
            case AppConstants.Habits.ID.sleep:
                return sleep
            case AppConstants.Habits.ID.breathing:
                return breathing
            case AppConstants.Habits.ID.meditation:
                return meditation
            case AppConstants.Habits.ID.water:
                return water
            case AppConstants.Habits.ID.sport:
                return sport
            case AppConstants.Habits.ID.nature:
                return nature
            case AppConstants.Habits.ID.social:
                return social
            case AppConstants.Habits.ID.journal:
                return journal
            default:
                return habitId
            }
        }
    }

    // MARK: - Frequency
    struct Frequency {
        static var daily: String { "frequency.label.daily".localized() }
        static var onePerWeek: String { "frequency.label.1x_week".localized() }
        static var twoPerWeek: String { "frequency.label.2x_week".localized() }
        static var threePerWeek: String { "frequency.label.3x_week".localized() }
        static var fourPerWeek: String { "frequency.label.4x_week".localized() }
        static var fivePerWeek: String { "frequency.label.5x_week".localized() }

        // Helper function to get frequency label by count
        static func label(for count: Int) -> String {
            switch count {
            case 7:
                return daily
            case 5:
                return fivePerWeek
            case 4:
                return fourPerWeek
            case 3:
                return threePerWeek
            case 2:
                return twoPerWeek
            case 1:
                return onePerWeek
            default:
                return daily
            }
        }
    }

    // MARK: - Tasks View
    struct TasksView {
        static var encouragementDefault: String { "tasks.view.encouragement_default".localized() }
        static var loading: String { "tasks.view.loading".localized() }
        static var noTasksToday: String { "tasks.view.no_tasks_today".localized() }
        static var allDone: String { "tasks.view.all_done".localized() }
    }

    // MARK: - Motivational Messages
    struct Motivational {
        // Time-based titles
        static var titleMorning: String { "motivational.title.morning".localized() }
        static var titleAfternoon: String { "motivational.title.afternoon".localized() }
        static var titleEvening: String { "motivational.title.evening".localized() }
        static var titleNight: String { "motivational.title.night".localized() }

        // Greetings by time of day
        static var greetingMorning: String { "motivational.greeting.morning".localized() }
        static var greetingAfternoon: String { "motivational.greeting.afternoon".localized() }
        static var greetingEvening: String { "motivational.greeting.evening".localized() }

        // 20 motivational messages (0-19)
        static var message0: String { "motivational.message.0".localized() }
        static var message1: String { "motivational.message.1".localized() }
        static var message2: String { "motivational.message.2".localized() }
        static var message3: String { "motivational.message.3".localized() }
        static var message4: String { "motivational.message.4".localized() }
        static var message5: String { "motivational.message.5".localized() }
        static var message6: String { "motivational.message.6".localized() }
        static var message7: String { "motivational.message.7".localized() }
        static var message8: String { "motivational.message.8".localized() }
        static var message9: String { "motivational.message.9".localized() }
        static var message10: String { "motivational.message.10".localized() }
        static var message11: String { "motivational.message.11".localized() }
        static var message12: String { "motivational.message.12".localized() }
        static var message13: String { "motivational.message.13".localized() }
        static var message14: String { "motivational.message.14".localized() }
        static var message15: String { "motivational.message.15".localized() }
        static var message16: String { "motivational.message.16".localized() }
        static var message17: String { "motivational.message.17".localized() }
        static var message18: String { "motivational.message.18".localized() }
        static var message19: String { "motivational.message.19".localized() }
    }

    // MARK: - Errors
    struct Errors {
        // Generic
        static var genericTitle: String { "error.title.generic".localized() }

        // Authentication Errors
        static var authFailed: String { "error.auth.failed".localized() }
        static var userNotFound: String { "error.auth.user_not_found".localized() }
        static var invalidCredentials: String { "error.auth.invalid_credentials".localized() }
        static var sessionExpired: String { "error.auth.session_expired".localized() }
        static var emailInUse: String { "error.auth.email_in_use".localized() }
        static var weakPassword: String { "error.auth.weak_password".localized() }

        // Network Errors
        static var networkUnavailable: String { "error.network.unavailable".localized() }
        static var serverError: String { "error.network.server_error".localized() }
        static var timeout: String { "error.network.timeout".localized() }
        static var invalidResponse: String { "error.network.invalid_response".localized() }

        // Data Errors
        static var dataCorrupted: String { "error.data.corrupted".localized() }
        static var documentNotFound: String { "error.data.document_not_found".localized() }
        static var saveFailed: String { "error.data.save_failed".localized() }
        static var fetchFailed: String { "error.data.fetch_failed".localized() }
        static var decodingFailed: String { "error.data.decoding_failed".localized() }
        static var encodingFailed: String { "error.data.encoding_failed".localized() }

        // Validation Errors
        static var invalidInput: String { "error.validation.invalid_input".localized() }
        static var missingField: String { "error.validation.missing_field".localized() }
        static var invalidFormat: String { "error.validation.invalid_format".localized() }

        // Business Logic Errors
        static var notAllowed: String { "error.business.not_allowed".localized() }
        static var insufficientPermissions: String { "error.business.insufficient_permissions".localized() }
        static var resourceUnavailable: String { "error.business.resource_unavailable".localized() }
        static var dailyLimit: String { "error.business.daily_limit".localized() }

        // Recovery Suggestions
        static var checkConnection: String { "error.recovery.check_connection".localized() }
        static var checkCredentials: String { "error.recovery.check_credentials".localized() }
        static var signInAgain: String { "error.recovery.sign_in_again".localized() }
        static var strongerPassword: String { "error.recovery.stronger_password".localized() }
        static var tryAgain: String { "error.recovery.try_again".localized() }
        static var tryTomorrow: String { "error.recovery.try_tomorrow".localized() }

        // Actions
        static var retry: String { "error.action.retry".localized() }
        static var signIn: String { "error.action.sign_in".localized() }
    }

    // MARK: - Alerts
    struct Alerts {
        // Task Completion
        static var taskCompletionTitle: String { "alert.task_completion.title".localized() }
        static var taskCompletionMessage: String { "alert.task_completion.message".localized() }

        // Error
        static var errorTitle: String { "alert.error.title".localized() }
        static var errorGenericMessage: String { "alert.error.generic_message".localized() }
    }

    // MARK: - AntiStress
    struct AntiStress {
        // Stress Situations
        struct Situations {
            static var overwhelmed: String { "antistress.situation.overwhelmed".localized() }
            static var insomnia: String { "antistress.situation.insomnia".localized() }
            static var physicalTension: String { "antistress.situation.physical_tension".localized() }
            static var beforeEvent: String { "antistress.situation.before_event".localized() }
            static var anxiety: String { "antistress.situation.anxiety".localized() }
            static var needEnergy: String { "antistress.situation.need_energy".localized() }
        }

        // Exercise Names
        struct ExerciseNames {
            static var guidedBreathing: String { "antistress.exercise.guided_breathing".localized() }
            static var grounding5Senses: String { "antistress.exercise.grounding_5_senses".localized() }
            static var consciousStretching: String { "antistress.exercise.conscious_stretching".localized() }
            static var cardiacCoherence: String { "antistress.exercise.cardiac_coherence".localized() }
            static var audioRelaxation: String { "antistress.exercise.audio_relaxation".localized() }
            static var bodyScan: String { "antistress.exercise.body_scan".localized() }
            static var boxBreathing: String { "antistress.exercise.box_breathing".localized() }
            static var anchoring54321: String { "antistress.exercise.anchoring_54321".localized() }
            static var positiveMantra: String { "antistress.exercise.positive_mantra".localized() }
            static var visualMicroBreak: String { "antistress.exercise.visual_micro_break".localized() }
            static var alternateBreathing: String { "antistress.exercise.alternate_breathing".localized() }
            static var slowWalk: String { "antistress.exercise.slow_walk".localized() }
            static var consciousBreathing: String { "antistress.exercise.conscious_breathing".localized() }
            static var meditation2Min: String { "antistress.exercise.meditation_2_min".localized() }
            static var whiteNoise: String { "antistress.exercise.white_noise".localized() }
        }

        // Exercise Descriptions
        struct ExerciseDescriptions {
            static var guidedBreathing: String { "antistress.description.guided_breathing".localized() }
            static var grounding5Senses: String { "antistress.description.grounding_5_senses".localized() }
            static var consciousStretching: String { "antistress.description.conscious_stretching".localized() }
            static var cardiacCoherence: String { "antistress.description.cardiac_coherence".localized() }
            static var audioRelaxation: String { "antistress.description.audio_relaxation".localized() }
            static var bodyScan: String { "antistress.description.body_scan".localized() }
            static var boxBreathing: String { "antistress.description.box_breathing".localized() }
            static var anchoring54321: String { "antistress.description.anchoring_54321".localized() }
            static var positiveMantra: String { "antistress.description.positive_mantra".localized() }
            static var visualMicroBreak: String { "antistress.description.visual_micro_break".localized() }
            static var alternateBreathing: String { "antistress.description.alternate_breathing".localized() }
            static var slowWalk: String { "antistress.description.slow_walk".localized() }
            static var consciousBreathing: String { "antistress.description.conscious_breathing".localized() }
            static var meditation2Min: String { "antistress.description.meditation_2_min".localized() }
            static var whiteNoise: String { "antistress.description.white_noise".localized() }
        }
    }
}