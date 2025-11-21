//
//  StringKeys.swift
//  CortiFree
//
//  Centralized localization keys for the entire app
//  Created by Claude on 17/11/2025.
//

import Foundation

// MARK: - Localization Keys Structure
// Organized by screen/feature for easy maintenance

struct StringKeys {

    // MARK: - Common
    struct Common {
        static let defaultUserName = "common.default_user_name" // "Champion"
        static let defaultUser = "common.default_user" // "Utilisateur"
        static let close = "common.close" // "Fermer"
        static let cancel = "common.cancel" // "Annuler"
        static let validate = "common.validate" // "Valider"
        static let skip = "common.skip" // "Passer"
        static let start = "common.start" // "Commencer"
        static let stop = "common.stop" // "Arrêter"
        static let pause = "common.pause" // "Pause"
        static let resume = "common.resume" // "Reprendre"
        static let continueButton = "common.continue" // "Continuer"
        static let next = "common.next" // "Suivant"
        static let previous = "common.previous" // "Précédent"
        static let day = "common.day" // "jour"
        static let days = "common.days" // "jours"
        static let week = "common.week" // "semaine"
        static let weeks = "common.weeks" // "semaines"
        static let hour = "common.hour" // "heure"
        static let hours = "common.hours" // "heures"
        static let minute = "common.minute" // "minute"
        static let minutes = "common.minutes" // "minutes"
        static let second = "common.second" // "seconde"
        static let seconds = "common.seconds" // "secondes"
        static let seeMore = "common.see_more" // "Voir plus"
        static let seeLess = "common.see_less" // "Voir moins"
        static let score = "common.score" // "score"
        static let streak = "common.streak" // "série"
        static let global = "common.global" // "Global"
        static let current = "common.current" // "Actuel"
        static let potential = "common.potential" // "Potentiel (J66)"
        static let serenity = "common.serenity" // "Sérénité"
        static let sleep = "common.sleep" // "Sommeil"
        static let energy = "common.energy" // "Énergie"
        static let focus = "common.focus" // "Focus"
        static let balance = "common.balance" // "Équilibre"
    }

    // MARK: - Tab Bar
    struct TabBar {
        static let home = "tab.home" // Already exists
        static let plan = "tab.plan" // Already exists
        static let library = "tab.library" // Already exists
        static let profile = "tab.profile" // Already exists
    }

    // MARK: - Onboarding
    struct Onboarding {

        // MARK: Overall Quiz
        struct OverallQuiz {
            static let title = "onboarding.overall_quiz.title" // "Quelques questions pour commencer"
            static let firstNameLabel = "onboarding.overall_quiz.first_name_label" // "Ton prénom ?"
            static let firstNamePlaceholder = "onboarding.overall_quiz.first_name_placeholder" // "Entre ton prénom"
            static let ageLabel = "onboarding.overall_quiz.age_label" // "Ton âge ?"
            static let genderLabel = "onboarding.overall_quiz.gender_label" // "Ton genre ?"
            static let stressReasonLabel = "onboarding.overall_quiz.stress_reason_label" // "Qu'est-ce qui te stresse ?"
            static let stressDurationLabel = "onboarding.overall_quiz.stress_duration_label" // "Depuis combien de temps ?"

            // Age options
            static let age1824 = "onboarding.overall_quiz.age_18_24" // "18-24 ans"
            static let age2534 = "onboarding.overall_quiz.age_25_34" // "25-34 ans"
            static let age3544 = "onboarding.overall_quiz.age_35_44" // "35-44 ans"
            static let age4554 = "onboarding.overall_quiz.age_45_54" // "45-54 ans"
            static let age55Plus = "onboarding.overall_quiz.age_55_plus" // "55+ ans"

            // Gender options
            static let genderMale = "onboarding.overall_quiz.gender_male" // "Homme"
            static let genderFemale = "onboarding.overall_quiz.gender_female" // "Femme"
            static let genderOther = "onboarding.overall_quiz.gender_other" // "Autre"
            static let genderPreferNot = "onboarding.overall_quiz.gender_prefer_not" // "Préfère ne pas dire"

            // Stress reasons
            static let reasonWork = "onboarding.overall_quiz.reason_work" // "Travail"
            static let reasonFinances = "onboarding.overall_quiz.reason_finances" // "Finances"
            static let reasonRelationships = "onboarding.overall_quiz.reason_relationships" // "Relations"
            static let reasonHealth = "onboarding.overall_quiz.reason_health" // "Santé"
            static let reasonFamily = "onboarding.overall_quiz.reason_family" // "Famille"
            static let reasonStudies = "onboarding.overall_quiz.reason_studies" // "Études"
            static let reasonFuture = "onboarding.overall_quiz.reason_future" // "Avenir"
            static let reasonOther = "onboarding.overall_quiz.reason_other" // "Autre"

            // Duration options
            static let durationLessThan1Month = "onboarding.overall_quiz.duration_less_1_month" // "Moins d'1 mois"
            static let duration13Months = "onboarding.overall_quiz.duration_1_3_months" // "1-3 mois"
            static let duration36Months = "onboarding.overall_quiz.duration_3_6_months" // "3-6 mois"
            static let duration612Months = "onboarding.overall_quiz.duration_6_12_months" // "6-12 mois"
            static let durationMoreThan1Year = "onboarding.overall_quiz.duration_more_1_year" // "Plus d'1 an"
        }

        // MARK: Habits Quiz
        struct HabitsQuiz {
            static let title = "onboarding.habits_quiz.title" // "Évalue tes habitudes actuelles"
            static let subtitle = "onboarding.habits_quiz.subtitle" // "Réponds honnêtement pour un plan personnalisé"
            static let questionOf = "onboarding.habits_quiz.question_of" // "Question %d sur %d"

            // Questions
            static let q1 = "onboarding.habits_quiz.q1" // "À quelle fréquence médites-tu ?"
            static let q2 = "onboarding.habits_quiz.q2" // "Pratiques-tu des exercices de respiration ?"
            static let q3 = "onboarding.habits_quiz.q3" // "Écris-tu régulièrement dans un journal ?"
            static let q4 = "onboarding.habits_quiz.q4" // "À quelle fréquence fais-tu du sport ?"
            static let q5 = "onboarding.habits_quiz.q5" // "Bois-tu suffisamment d'eau chaque jour ?"
            static let q6 = "onboarding.habits_quiz.q6" // "Passes-tu du temps dans la nature ?"
            static let q7 = "onboarding.habits_quiz.q7" // "Comment évalues-tu la qualité de ton sommeil ?"
            static let q8 = "onboarding.habits_quiz.q8" // "Entretiens-tu des relations sociales régulières ?"
            static let q9 = "onboarding.habits_quiz.q9" // "Te sens-tu souvent stressé ou anxieux ?"
            static let q10 = "onboarding.habits_quiz.q10" // "As-tu des moments de détente dans ta journée ?"
            static let q11 = "onboarding.habits_quiz.q11" // "Gères-tu bien tes émotions ?"
            static let q12 = "onboarding.habits_quiz.q12" // "Te sens-tu énergique au quotidien ?"

            // Answer options (generic)
            static let never = "onboarding.habits_quiz.answer_never" // "Jamais"
            static let rarely = "onboarding.habits_quiz.answer_rarely" // "Rarement"
            static let sometimes = "onboarding.habits_quiz.answer_sometimes" // "Parfois"
            static let often = "onboarding.habits_quiz.answer_often" // "Souvent"
            static let always = "onboarding.habits_quiz.answer_always" // "Toujours"
        }

        // MARK: Rating View
        struct Rating {
            static let currentTitle = "onboarding.rating.current_title" // "Ton évaluation actuelle"
            static let potentialTitle = "onboarding.rating.potential_title" // "Ton évaluation potentielle"
            static let potentialSubtitle = "onboarding.rating.potential_subtitle" // "après 66 jours"
            static let seePotential = "onboarding.rating.see_potential" // "Voir le potentiel"
        }

        // MARK: Eight Habits Intro
        struct EightHabitsIntro {
            static let title = "onboarding.eight_habits_intro.title" // "Les 8 habitudes clés pour diminuer ton stress"
            static let subtitle = "onboarding.eight_habits_intro.subtitle" // "Chaque habitude a été sélectionnée pour son impact scientifiquement prouvé sur la réduction du cortisol"
            static let habitMeditation = "onboarding.eight_habits_intro.habit_meditation" // "Méditation"
            static let habitBreathing = "onboarding.eight_habits_intro.habit_breathing" // "Respiration"
            static let habitJournal = "onboarding.eight_habits_intro.habit_journal" // "Journal"
            static let habitSport = "onboarding.eight_habits_intro.habit_sport" // "Sport"
            static let habitWater = "onboarding.eight_habits_intro.habit_water" // "Eau"
            static let habitNature = "onboarding.eight_habits_intro.habit_nature" // "Nature"
            static let habitSleep = "onboarding.eight_habits_intro.habit_sleep" // "Sommeil"
            static let habitSocial = "onboarding.eight_habits_intro.habit_social" // "Social"
        }

        // MARK: Eight Habits Flow
        struct EightHabitsFlow {
            static let seeDetails = "onboarding.eight_habits_flow.see_details" // "Voir en détail les 8 habitudes"
            static let howHabitsHelp = "onboarding.eight_habits_flow.how_habits_help" // "Comment les 8 habitudes vous aident"

            // Meditation
            static let meditationTitle = "onboarding.eight_habits_flow.meditation_title" // "Méditation en pleine conscience"
            static let meditationSubtitle = "onboarding.eight_habits_flow.meditation_subtitle" // "Calme l'esprit, réduit le stress"
            static let meditationBenefit1 = "onboarding.eight_habits_flow.meditation_benefit_1" // "Réduit l'anxiété de 30%"
            static let meditationBenefit2 = "onboarding.eight_habits_flow.meditation_benefit_2" // "Améliore la concentration"
            static let meditationBenefit3 = "onboarding.eight_habits_flow.meditation_benefit_3" // "Diminue le cortisol"
            static let meditationImpactSerenity = "onboarding.eight_habits_flow.meditation_impact_serenity" // "Sérénité"
            static let meditationImpactFocus = "onboarding.eight_habits_flow.meditation_impact_focus" // "Focus"
            static let meditationImpactBalance = "onboarding.eight_habits_flow.meditation_impact_balance" // "Équilibre"

            // Breathing
            static let breathingTitle = "onboarding.eight_habits_flow.breathing_title" // "Exercices de respiration"
            static let breathingSubtitle = "onboarding.eight_habits_flow.breathing_subtitle" // "Apaise instantanément le système nerveux"
            static let breathingBenefit1 = "onboarding.eight_habits_flow.breathing_benefit_1" // "Calme immédiat"
            static let breathingBenefit2 = "onboarding.eight_habits_flow.breathing_benefit_2" // "Régule le rythme cardiaque"
            static let breathingBenefit3 = "onboarding.eight_habits_flow.breathing_benefit_3" // "Réduit la tension"
            static let breathingImpactSerenity = "onboarding.eight_habits_flow.breathing_impact_serenity" // "Sérénité"
            static let breathingImpactEnergy = "onboarding.eight_habits_flow.breathing_impact_energy" // "Énergie"

            // Journal
            static let journalTitle = "onboarding.eight_habits_flow.journal_title" // "Tenue d'un journal"
            static let journalSubtitle = "onboarding.eight_habits_flow.journal_subtitle" // "Libère les pensées, clarifie l'esprit"
            static let journalBenefit1 = "onboarding.eight_habits_flow.journal_benefit_1" // "Réduit les ruminations"
            static let journalBenefit2 = "onboarding.eight_habits_flow.journal_benefit_2" // "Améliore l'humeur"
            static let journalBenefit3 = "onboarding.eight_habits_flow.journal_benefit_3" // "Clarifie les émotions"
            static let journalImpactSerenity = "onboarding.eight_habits_flow.journal_impact_serenity" // "Sérénité"
            static let journalImpactBalance = "onboarding.eight_habits_flow.journal_impact_balance" // "Équilibre"

            // Sport
            static let sportTitle = "onboarding.eight_habits_flow.sport_title" // "Activité physique régulière"
            static let sportSubtitle = "onboarding.eight_habits_flow.sport_subtitle" // "Libère les endorphines, brûle le stress"
            static let sportBenefit1 = "onboarding.eight_habits_flow.sport_benefit_1" // "Augmente les endorphines"
            static let sportBenefit2 = "onboarding.eight_habits_flow.sport_benefit_2" // "Réduit le cortisol"
            static let sportBenefit3 = "onboarding.eight_habits_flow.sport_benefit_3" // "Améliore l'humeur"
            static let sportImpactEnergy = "onboarding.eight_habits_flow.sport_impact_energy" // "Énergie"
            static let sportImpactSleep = "onboarding.eight_habits_flow.sport_impact_sleep" // "Sommeil"
            static let sportImpactBalance = "onboarding.eight_habits_flow.sport_impact_balance" // "Équilibre"

            // Water
            static let waterTitle = "onboarding.eight_habits_flow.water_title" // "Hydratation optimale"
            static let waterSubtitle = "onboarding.eight_habits_flow.water_subtitle" // "Essentielle pour le cerveau et le corps"
            static let waterBenefit1 = "onboarding.eight_habits_flow.water_benefit_1" // "Améliore la concentration"
            static let waterBenefit2 = "onboarding.eight_habits_flow.water_benefit_2" // "Réduit la fatigue"
            static let waterBenefit3 = "onboarding.eight_habits_flow.water_benefit_3" // "Optimise les fonctions cérébrales"
            static let waterImpactEnergy = "onboarding.eight_habits_flow.water_impact_energy" // "Énergie"
            static let waterImpactFocus = "onboarding.eight_habits_flow.water_impact_focus" // "Focus"

            // Nature
            static let natureTitle = "onboarding.eight_habits_flow.nature_title" // "Contact avec la nature"
            static let natureSubtitle = "onboarding.eight_habits_flow.nature_subtitle" // "Reconnecte, ressource, revitalise"
            static let natureBenefit1 = "onboarding.eight_habits_flow.nature_benefit_1" // "Baisse la pression artérielle"
            static let natureBenefit2 = "onboarding.eight_habits_flow.nature_benefit_2" // "Réduit le stress mental"
            static let natureBenefit3 = "onboarding.eight_habits_flow.nature_benefit_3" // "Améliore l'humeur"
            static let natureImpactSerenity = "onboarding.eight_habits_flow.nature_impact_serenity" // "Sérénité"
            static let natureImpactBalance = "onboarding.eight_habits_flow.nature_impact_balance" // "Équilibre"

            // Sleep
            static let sleepTitle = "onboarding.eight_habits_flow.sleep_title" // "Sommeil de qualité"
            static let sleepSubtitle = "onboarding.eight_habits_flow.sleep_subtitle" // "Pilier de la récupération et de la santé"
            static let sleepBenefit1 = "onboarding.eight_habits_flow.sleep_benefit_1" // "Régénère le corps et l'esprit"
            static let sleepBenefit2 = "onboarding.eight_habits_flow.sleep_benefit_2" // "Réduit le cortisol"
            static let sleepBenefit3 = "onboarding.eight_habits_flow.sleep_benefit_3" // "Améliore la mémoire"
            static let sleepImpactSleep = "onboarding.eight_habits_flow.sleep_impact_sleep" // "Sommeil"
            static let sleepImpactEnergy = "onboarding.eight_habits_flow.sleep_impact_energy" // "Énergie"
            static let sleepImpactFocus = "onboarding.eight_habits_flow.sleep_impact_focus" // "Focus"

            // Social
            static let socialTitle = "onboarding.eight_habits_flow.social_title" // "Connexions sociales"
            static let socialSubtitle = "onboarding.eight_habits_flow.social_subtitle" // "Le soutien social, antidote au stress"
            static let socialBenefit1 = "onboarding.eight_habits_flow.social_benefit_1" // "Réduit l'anxiété"
            static let socialBenefit2 = "onboarding.eight_habits_flow.social_benefit_2" // "Augmente l'ocytocine"
            static let socialBenefit3 = "onboarding.eight_habits_flow.social_benefit_3" // "Renforce le bien-être"
            static let socialImpactSerenity = "onboarding.eight_habits_flow.social_impact_serenity" // "Sérénité"
            static let socialImpactBalance = "onboarding.eight_habits_flow.social_impact_balance" // "Équilibre"

            // Common
            static let benefitsTitle = "onboarding.eight_habits_flow.benefits_title" // "Bénéfices scientifiques"
            static let impactOnTitle = "onboarding.eight_habits_flow.impact_on_title" // "Impact sur"
        }

        // MARK: Week Progress
        struct WeekProgress {
            static let weekNumber = "onboarding.week_progress.week_number" // "Semaine %d"
            static let week1Message = "onboarding.week_progress.week_1_message" // "Tu débutes — ton départ est un peu faible."
            static let week5Message = "onboarding.week_progress.week_5_message" // "Tu progresses — continue comme ça !"
            static let week10Message = "onboarding.week_progress.week_10_message" // "Tu maîtrises tous les domaines — ton progrès est évident !"
        }

        // MARK: Habits Progress Flow
        struct HabitsProgressFlow {
            static let title = "onboarding.habits_progress_flow.title" // "Évolution de tes habitudes"
            static let subtitle = "onboarding.habits_progress_flow.subtitle" // "Vois comment tes efforts se transforment en résultats concrets"
            static let weekLabel = "onboarding.habits_progress_flow.week_label" // "Semaine"
            static let progressLabel = "onboarding.habits_progress_flow.progress_label" // "Progrès"
        }

        // MARK: Social Proof - Testimonials
        struct Testimonials {
            static let title = "onboarding.testimonials.title" // "Ils ont transformé leur vie"
            static let subtitle = "onboarding.testimonials.subtitle" // "Rejoins des milliers d'utilisateurs qui ont réduit leur stress"

            static let testimonial1Name = "onboarding.testimonials.testimonial_1_name" // "Marie L."
            static let testimonial1Age = "onboarding.testimonials.testimonial_1_age" // "32 ans"
            static let testimonial1Text = "onboarding.testimonials.testimonial_1_text" // "En 10 semaines, j'ai appris à gérer mon stress au travail. Les exercices de respiration sont devenus mon réflexe dans les moments difficiles."

            static let testimonial2Name = "onboarding.testimonials.testimonial_2_name" // "Thomas D."
            static let testimonial2Age = "onboarding.testimonials.testimonial_2_age" // "28 ans"
            static let testimonial2Text = "onboarding.testimonials.testimonial_2_text" // "J'étais sceptique au début, mais la méditation guidée et le suivi des habitudes ont vraiment changé ma qualité de vie. Je dors mieux et je me sens plus calme."

            static let testimonial3Name = "onboarding.testimonials.testimonial_3_name" // "Sophie M."
            static let testimonial3Age = "onboarding.testimonials.testimonial_3_age" // "45 ans"
            static let testimonial3Text = "onboarding.testimonials.testimonial_3_text" // "Le journal de gratitude m'a aidée à voir les choses positivement. Après 66 jours, c'est devenu une habitude naturelle."

            static let testimonial4Name = "onboarding.testimonials.testimonial_4_name" // "Lucas B."
            static let testimonial4Age = "onboarding.testimonials.testimonial_4_age" // "35 ans"
            static let testimonial4Text = "onboarding.testimonials.testimonial_4_text" // "L'approche scientifique m'a convaincu. Chaque exercice est basé sur des études, et les résultats sont au rendez-vous."
        }

        // MARK: Social Proof - Goals Selection
        struct GoalsSelection {
            static let title = "onboarding.goals_selection.title" // "Quel est ton objectif principal ?"
            static let subtitle = "onboarding.goals_selection.subtitle" // "Sélectionne jusqu'à 3 objectifs"

            static let goal1 = "onboarding.goals_selection.goal_1" // "Réduire mon stress au quotidien"
            static let goal2 = "onboarding.goals_selection.goal_2" // "Mieux dormir"
            static let goal3 = "onboarding.goals_selection.goal_3" // "Augmenter mon énergie"
            static let goal4 = "onboarding.goals_selection.goal_4" // "Améliorer ma concentration"
            static let goal5 = "onboarding.goals_selection.goal_5" // "Trouver l'équilibre vie pro/perso"
            static let goal6 = "onboarding.goals_selection.goal_6" // "Gérer mes émotions"
            static let goal7 = "onboarding.goals_selection.goal_7" // "Développer la pleine conscience"
            static let goal8 = "onboarding.goals_selection.goal_8" // "Créer des habitudes saines"

            static let selectionCount = "onboarding.goals_selection.selection_count" // "%d/3 sélectionnés"
        }

        // MARK: Authentication
        struct Authentication {
            static let title = "onboarding.auth.title" // "Crée ton compte pour commencer"
            static let subtitle = "onboarding.auth.subtitle" // "Sauvegarde ta progression et accède à ton programme personnalisé"
            static let emailPlaceholder = "onboarding.auth.email_placeholder" // "Adresse email"
            static let passwordPlaceholder = "onboarding.auth.password_placeholder" // "Mot de passe"
            static let signInButton = "onboarding.auth.sign_in_button" // "Se connecter"
            static let signUpButton = "onboarding.auth.sign_up_button" // "S'inscrire"
            static let orContinueWith = "onboarding.auth.or_continue_with" // "Ou continue avec"
            static let googleButton = "onboarding.auth.google_button" // "Continuer avec Google"
            static let appleButton = "onboarding.auth.apple_button" // "Continuer avec Apple"
            static let alreadyHaveAccount = "onboarding.auth.already_have_account" // "Déjà un compte ?"
            static let noAccountYet = "onboarding.auth.no_account_yet" // "Pas encore de compte ?"
            static let forgotPassword = "onboarding.auth.forgot_password" // "Mot de passe oublié ?"
            static let resetPassword = "onboarding.auth.reset_password" // "Réinitialiser"
            static let backToLogin = "onboarding.auth.back_to_login" // "Retour à la connexion"
        }
    }

    // MARK: - Home Screen
    struct Home {
        static let congratulations = "home.congratulations" // "Félicitations %@,"
        static let programStarted = "home.program_started" // "tu as commencé le programme il y a :"
        static let keepShining = "home.keep_shining" // "Continue de briller"
        static let routineCountdown = "home.routine_countdown" // "Tu atteindras %@ dans :"
        static let antiStressButton = "home.antistress_button" // "Bouton Anti-Stress"
        static let breatheDeeply = "home.breathe_deeply" // "Respirez profondément"
        static let breatheIn = "home.breathe_in" // "Inspirez..."
        static let breatheOut = "home.breathe_out" // "Expirez..."
        static let neuroplasticity = "home.neuroplasticity" // "Neuroplasticité cérébrale"
        static let neuroplasticityDesc = "home.neuroplasticity_desc" // Long description
        static let why66Days = "home.why_66_days" // "Pourquoi 66 jours ?"
        static let why66DaysDesc = "home.why_66_days_desc" // Long description
        static let scientificEvidence = "home.scientific_evidence" // "Les preuves scientifiques"
        static let scientificEvidenceDesc = "home.scientific_evidence_desc" // Long description
    }

    // MARK: - Levels
    struct Levels {
        static let beginnerSerene = "level.beginner_serene" // "Débutant Serein"
        static let noviceCalm = "level.novice_calm" // "Novice Apaisé"
        static let apprenticeZen = "level.apprentice_zen" // "Apprenti Zen"
        static let practitionerAwakened = "level.practitioner_awakened" // "Pratiquant Éveillé"
        static let confirmedMeditator = "level.confirmed_meditator" // "Méditant Confirmé"
        static let expertCalm = "level.expert_calm" // "Expert du Calme"
        static let masterCalm = "level.master_calm" // "Maître du Calme"
        static let peacefulGuru = "level.peaceful_guru" // "Guru Paisible"
        static let enlightenedSage = "level.enlightened_sage" // "Sage Éclairé"
        static let immortalLegend = "level.immortal_legend" // "Légende Immortelle"
        static let supremeMaster = "level.supreme_master" // "Maître Suprême"
        static let novice = "level.novice" // "Novice"
    }

    // MARK: - Library Screen
    struct Library {
        static let title = "library.title" // "Librairie"

        // Categories
        static let learn = "library.category.learn" // "Apprendre"
        static let blog = "library.category.blog" // "Blog"
        static let tips = "library.category.tips" // "Conseils"
        static let studies = "library.category.studies" // "Études"

        // Sections
        static let relaxingSounds = "library.relaxing_sounds" // "Sons Relaxants"
        static let relaxingSoundsDesc = "library.relaxing_sounds_desc" // "Aide ton coeur à se réguler lors d'une situation stressante"
        static let breathingExercises = "library.breathing_exercises" // "Exercices de Respiration Guidés"
        static let breathingExercisesDesc = "library.breathing_exercises_desc" // "Techniques de respiration pour gérer le stress"
        static let meditationExercises = "library.meditation_exercises" // "Exercices de Méditation Guidés"
        static let meditationExercisesDesc = "library.meditation_exercises_desc" // "Méditations guidées pour la relaxation profonde"

        // Sound Names
        static let soundRain = "library.sound.rain" // "Pluie"
        static let soundOcean = "library.sound.ocean" // "Ocean"
        static let soundFire = "library.sound.fire" // "Feu"
        static let soundWhiteNoise = "library.sound.white_noise" // "Bruit Blanc"
        static let soundMorning = "library.sound.morning" // "Matinée"
        static let soundForest = "library.sound.forest" // "Forêt"
        static let soundStream = "library.sound.stream" // "Ruisseau"
        static let soundSummerNight = "library.sound.summer_night" // "Nuit d'été"

        // Header sections (LibraryHeaderView)
        static let respiration = "library.section.respiration" // "Respiration"
        static let meditation = "library.section.meditation" // "Méditation"
        static let journal = "library.section.journal" // "Journal"
        static let research = "library.section.research" // "Études"
    }

    // MARK: - Profile Screen
    struct Profile {
        static let scoreCortiFree = "profile.score_cortifree" // "Score CortiFree"
        static let habits = "profile.habits" // "Habitudes"
        static let dayProgress = "profile.day_progress" // "Jour %d/66"

        // Habit Names
        static let habitMeditation = "profile.habit.meditation" // "Méditation"
        static let habitBreathing = "profile.habit.breathing" // "Respiration"
        static let habitJournal = "profile.habit.journal" // "Journal"
        static let habitSport = "profile.habit.sport" // "Sport"
        static let habitWater = "profile.habit.water" // "Eau"
        static let habitNature = "profile.habit.nature" // "Nature"
        static let habitSleep = "profile.habit.sleep" // "Sommeil"
        static let habitSocial = "profile.habit.social" // "Social"

        // Domain Names
        static let domainSerenity = "profile.domain.serenity" // "Sérénité"
        static let domainSleep = "profile.domain.sleep" // "Sommeil"
        static let domainEnergy = "profile.domain.energy" // "Énergie"
        static let domainFocus = "profile.domain.focus" // "Focus"
        static let domainBalance = "profile.domain.balance" // "Équilibre"

        // Edit Profile
        static let editTitle = "profile.edit.title" // "Mon Profil"
        static let save = "profile.edit.save" // "Sauvegarder"
        static let personalInfo = "profile.edit.personal_info" // "Informations personnelles"
        static let firstName = "profile.edit.first_name" // "Prénom"
        static let sleepSection = "profile.edit.sleep_section" // "Sommeil"
        static let bedTime = "profile.edit.bed_time" // "Heure de coucher"
        static let wakeTime = "profile.edit.wake_time" // "Heure de réveil"
        static let goalsSection = "profile.edit.goals_section" // "Objectifs après 10 semaines"
        static let currentSection = "profile.edit.current_section" // "Actuellement"
        static let frequencyLabel = "profile.edit.frequency_label" // "Fréquence"
        static let durationLabel = "profile.edit.duration_label" // "Durée"
        static let quantityLabel = "profile.edit.quantity_label" // "Quantité"
        static let applyNextWeek = "profile.edit.apply_next_week" // "Les modifications seront appliquées à partir du %@"
        static let frequencyDaily = "profile.habit.frequency.daily" // "Quotidien"
        static let frequencyWeek = "profile.habit.frequency.week" // "sem"
        static let timesPerWeek = "profile.habit.times_per_week" // "%d fois/semaine"
        static let minutesPerSession = "profile.habit.minutes_per_session" // "%d min/session"
        static let litersPerDay = "profile.habit.liters_per_day" // "%.1f L/jour"
        static let hoursPerNight = "profile.habit.hours_per_night" // "%.1f h/nuit"
        static let routineDuration = "profile.habit.routine_duration" // "Routine de %d min"
        static let completionRate = "profile.habit.completion_rate" // "Taux de complétion: %@"
        static let noDataYet = "profile.habit.no_data_yet" // "Pas encore de données"
    }

    // MARK: - Tasks Screen
    struct Tasks {
        static let todo = "tasks.todo" // Already exists
        static let done = "tasks.done" // Already exists
        static let skipped = "tasks.skipped" // Already exists
        static let dayProgress = "tasks.day_progress" // "Jour %d/66"
        static let encouragement = "tasks.encouragement" // "Tu fais du super boulot. Continue !"

        // Task Titles
        static let breathConsciously = "tasks.breathe_consciously" // "Respirer en conscience"
        static let meditateMindfully = "tasks.meditate_mindfully" // "Méditer en pleine conscience"
        static let drinkWater = "tasks.drink_water" // "Boire au minimum %@ d'eau"
        static let writeThoughts = "tasks.write_thoughts" // "Écrire ses pensées"
        static let doSport = "tasks.do_sport" // "Faire du sport"
        static let goOutside = "tasks.go_outside" // "Sortir dehors"
        static let goodSleep = "tasks.good_sleep" // "Bien dormir"
        static let socialTime = "tasks.social_time" // "Moment social"
    }

    // MARK: - Settings Screen
    struct Settings {
        static let title = "settings.title" // "Paramètres"
        static let language = "settings.language" // Already exists
        static let chooseLanguage = "settings.choose_language" // Already exists
        static let languageSubtitle = "settings.language_subtitle" // Already exists
        static let languageRestartNote = "settings.language_restart_note" // Already exists

        // Alerts
        static let logout = "settings.logout" // "Se déconnecter"
        static let logoutConfirm = "settings.logout_confirm" // "Êtes-vous sûr de vouloir vous déconnecter ?"
        static let deleteAccount = "settings.delete_account" // "Supprimer le compte"
        static let deleteAccountWarning = "settings.delete_account_warning" // "Cette action est irréversible. Toutes vos données seront définitivement supprimées."

        // Routine
        static let changeRoutine = "settings.change_routine" // "Changer de routine"
        static let selectNewRoutine = "settings.select_new_routine" // "Sélectionne ta nouvelle routine"
        static let warningTitle = "settings.warning_title" // "⚠️ Attention"
        static let changeRoutineWarning = "settings.change_routine_warning" // "Changer de routine réinitialisera :"

        // Sections
        static let notifications = "settings.notifications" // "Notifications"
        static let sounds = "settings.sounds" // "Sons"
        static let privacy = "settings.privacy" // "Confidentialité"
        static let about = "settings.about" // "À propos"
        static let help = "settings.help" // "Aide"
        static let version = "settings.version" // "Version"
        static let terms = "settings.terms" // "Conditions d'utilisation"
        static let privacyPolicy = "settings.privacy_policy" // "Politique de confidentialité"
    }

    // MARK: - Exercise Detail
    struct Exercise {
        static let start = "exercise.start" // "Commencer"
        static let stop = "exercise.stop" // "Arrêter"
        static let pause = "exercise.pause" // "Pause"
        static let resume = "exercise.resume" // "Reprendre"
        static let completed = "exercise.completed" // "Terminé"
        static let duration = "exercise.duration" // "Durée"
        static let description = "exercise.description" // "Description"
        static let benefits = "exercise.benefits" // "Bénéfices"
        static let howTo = "exercise.how_to" // "Comment faire"
    }

    // MARK: - Journal
    struct Journal {
        static let title = "journal.title" // "Mon Journal"
        static let streak = "journal.streak" // "%d jour(s)"
        static let create = "journal.create" // "Créer une entrée"
        static let save = "journal.save" // "Sauvegarder"
        static let saved = "journal.saved" // "Sauvegardé !"
        static let delete = "journal.delete" // "Supprimer"
        static let deleteConfirm = "journal.delete_confirm" // "Supprimer cette entrée ?"
        static let history = "journal.history" // "Historique"

        // Tabs
        static let gratitude = "journal.tab.gratitude" // "Gratitude"
        static let reflection = "journal.tab.reflection" // "Réflexion"
        static let goals = "journal.tab.goals" // "Objectifs"

        // Tab Descriptions
        static let gratitudeDesc = "journal.desc.gratitude" // "Ce pour quoi tu es reconnaissant"
        static let reflectionDesc = "journal.desc.reflection" // "Réfléchis sur ta journée"
        static let goalsDesc = "journal.desc.goals" // "Tes objectifs et ambitions"

        // Sheet Titles
        static let gratitudeTitle = "journal.title.gratitude" // "Journal de Gratitude"
        static let reflectionTitle = "journal.title.reflection" // "Réflexion du Jour"
        static let goalsTitle = "journal.title.goals" // "Mes Objectifs"

        // Stats
        static let thisWeek = "journal.stats.this_week" // "Cette semaine"
        static let averageMood = "journal.stats.average_mood" // "Humeur moyenne"
        static let totalEntries = "journal.stats.total_entries" // "Entrées"
        static let wordCount = "journal.stats.word_count" // "mots"
        static let words = "journal.stats.words" // "mots"

        // Empty States
        static let noEntries = "journal.empty.no_entries" // "Aucune entrée pour %@"
        static let startWriting = "journal.empty.start_writing" // "Commence à écrire..."

        // Prompts
        static let promptPlaceholder = "journal.prompt.placeholder" // "Votre réflexion"
        static let gratitudePlaceholder = "journal.prompt.gratitude" // "Ajoute quelque chose..."

        // Mood
        static let moodQuestion = "journal.mood.question" // "Comment te sens-tu ?"
        static let moodHide = "journal.mood.hide" // "Masquer"
        static let moodChange = "journal.mood.change" // "Changer"
    }
}