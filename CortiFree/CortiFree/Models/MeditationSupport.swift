//
//  MeditationSupport.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Types de support pour les exercices de méditation
//

import Foundation

enum MeditationSupportType {
    case instructions      // Instructions étape par étape
    case journal          // Journal de réflexion
    case guide           // Guide avec conseils
    case tracker         // Suivi et progression
    case visualGuide     // Guide visuel avec images
    case affirmations    // Affirmations positives
}

struct MeditationSupport: Identifiable, Equatable {
    static func == (lhs: MeditationSupport, rhs: MeditationSupport) -> Bool {
        lhs.meditationId == rhs.meditationId
    }

    var id: String { meditationId }
    let meditationId: String
    let supportType: MeditationSupportType
    let title: String
    let benefit: String  // Bénéfice principal de l'exercice
    let content: MeditationSupportContent
}

struct MeditationSupportContent {
    let sections: [SupportSection]
}

struct SupportSection {
    let title: String
    let content: String
    let tips: [String]?
    let prompts: [String]?  // For journal entries
    let steps: [String]?     // For instructions
    let affirmations: [String]? // For affirmations
}

// Configuration des supports pour chaque méditation
extension MeditationSupport {
    static let allSupports: [MeditationSupport] = [
        // Respiration consciente - Instructions
        MeditationSupport(
            meditationId: "conscious-breathing",
            supportType: .instructions,
            title: "Respiration consciente",
            benefit: "Premier pas en méditation - Apprenez à observer votre respiration naturelle.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Premiers pas",
                    content: "La respiration consciente est la base de toute pratique méditative. Observez simplement votre respiration sans chercher à la modifier.",
                    tips: [
                        "Trouvez une position confortable",
                        "Fermez doucement les yeux",
                        "Respirez naturellement"
                    ],
                    prompts: nil,
                    steps: [
                        "Prenez une position assise confortable",
                        "Portez votre attention sur votre respiration",
                        "Observez l'air qui entre et sort",
                        "Quand votre esprit s'égare, revenez doucement à la respiration",
                        "Continuez pendant 3 minutes"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Body Scan - Instructions
        MeditationSupport(
            meditationId: "body-scan",
            supportType: .instructions,
            title: "Body Scan",
            benefit: "Relâchez rapidement les tensions physiques accumulées dans votre corps.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Scan rapide",
                    content: "Parcourez mentalement votre corps pour identifier et relâcher les tensions.",
                    tips: [
                        "Allez vite sur chaque zone",
                        "Ne jugez pas les sensations",
                        "Respirez dans les zones tendues"
                    ],
                    prompts: nil,
                    steps: [
                        "Scannez vos pieds et chevilles",
                        "Montez vers vos jambes",
                        "Observez votre bassin et abdomen",
                        "Détendez votre poitrine et épaules",
                        "Relâchez votre nuque et visage"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Mindfulness - Guide
        MeditationSupport(
            meditationId: "mindfulness",
            supportType: .guide,
            title: "Mindfulness",
            benefit: "Apprenez à observer vos pensées sans vous y accrocher.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Observer sans juger",
                    content: "La pleine conscience consiste à observer vos pensées comme des nuages qui passent dans le ciel.",
                    tips: [
                        "Ne combattez pas vos pensées",
                        "Observez-les simplement",
                        "Revenez toujours à la respiration"
                    ],
                    prompts: nil,
                    steps: [
                        "Asseyez-vous confortablement",
                        "Fermez les yeux",
                        "Observez votre respiration",
                        "Quand une pensée arrive, notez-la mentalement",
                        "Laissez-la passer sans vous y attacher",
                        "Revenez à votre respiration"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Ancrage corporel - Guide
        MeditationSupport(
            meditationId: "grounding",
            supportType: .guide,
            title: "Ancrage corporel",
            benefit: "Technique d'urgence pour calmer l'anxiété et les crises de panique.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Technique 5-4-3-2-1",
                    content: "Reconnectez-vous instantanément au moment présent pour stopper l'anxiété.",
                    tips: [
                        "Utilisez en cas de crise",
                        "Dites à voix haute si possible",
                        "Prenez votre temps"
                    ],
                    prompts: nil,
                    steps: [
                        "Nommez 5 choses que vous VOYEZ",
                        "Nommez 4 choses que vous TOUCHEZ",
                        "Nommez 3 choses que vous ENTENDEZ",
                        "Nommez 2 choses que vous SENTEZ",
                        "Nommez 1 chose que vous GOÛTEZ"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Visualisation lieu sûr - Guide visuel
        MeditationSupport(
            meditationId: "visualization",
            supportType: .visualGuide,
            title: "Visualisation lieu sûr",
            benefit: "Créez un refuge mental pour retrouver le calme instantanément.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Votre sanctuaire mental",
                    content: "Créez un lieu sûr dans votre esprit où vous pouvez vous réfugier à tout moment.",
                    tips: [
                        "Choisissez un lieu réel ou imaginaire",
                        "Engagez tous vos sens",
                        "Rendez-le aussi détaillé que possible"
                    ],
                    prompts: nil,
                    steps: [
                        "Fermez les yeux",
                        "Imaginez un lieu où vous vous sentez en sécurité",
                        "Visualisez les couleurs, formes, lumières",
                        "Entendez les sons de ce lieu",
                        "Sentez les odeurs et sensations",
                        "Restez-y aussi longtemps que nécessaire"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Auto-compassion - Affirmations
        MeditationSupport(
            meditationId: "compassion",
            supportType: .affirmations,
            title: "Auto-compassion",
            benefit: "Cultivez la bienveillance envers vous-même et renforcez votre estime.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Bienveillance envers soi",
                    content: "Traitez-vous avec la même gentillesse que vous offririez à un ami cher.",
                    tips: [
                        "Placez votre main sur votre cœur",
                        "Ressentez vraiment chaque affirmation",
                        "Répétez 3 fois chacune"
                    ],
                    prompts: nil,
                    steps: nil,
                    affirmations: []
                )
            ])
        ),

        // Méditation focus - Tracker
        MeditationSupport(
            meditationId: "focus-clarity",
            supportType: .tracker,
            title: "Méditation focus",
            benefit: "Améliorez votre concentration et clarté mentale pour mieux décider.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Entraînement mental",
                    content: "Renforcez votre capacité de concentration comme un muscle.",
                    tips: [
                        "Choisissez un point focal (respiration, objet)",
                        "Revenez-y à chaque distraction",
                        "La clarté vient avec la pratique"
                    ],
                    prompts: [
                        "Avant : Mon esprit est... (agité/calme/confus)",
                        "Après : Je me sens...",
                        "J'ai gagné en clarté sur...",
                        "Demain, je vais..."
                    ],
                    steps: nil,
                    affirmations: nil
                )
            ])
        ),

        // Méditation sommeil - Guide
        MeditationSupport(
            meditationId: "yoga-nidra",
            supportType: .guide,
            title: "Méditation sommeil",
            benefit: "Préparez-vous à un sommeil profond et réparateur grâce à la relaxation totale.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Yoga Nidra - Sommeil yogique",
                    content: "Le Yoga Nidra est une pratique de relaxation profonde qui mène au sommeil conscient.",
                    tips: [
                        "Pratiquez allongé dans votre lit",
                        "Laissez-vous glisser vers le sommeil",
                        "Ne résistez pas si vous vous endormez"
                    ],
                    prompts: nil,
                    steps: [
                        "Allongez-vous confortablement",
                        "Scannez tout votre corps de la tête aux pieds",
                        "Relaxez chaque partie progressivement",
                        "Respirez lentement et profondément",
                        "Laissez votre corps s'enfoncer dans le matelas",
                        "Glissez doucement vers le sommeil"
                    ],
                    affirmations: nil
                )
            ])
        )
    ]

    static func support(for meditationId: String) -> MeditationSupport? {
        return allSupports.first { $0.meditationId == meditationId }
    }
}

// MARK: - Localized Content Extension

extension MeditationSupport {
    var localizedTitle: String {
        switch meditationId {
        case "conscious-breathing": return LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.title")
        case "body-scan": return LanguageManager.shared.localizedString(for: "meditation.body_scan.title")
        case "mindfulness": return LanguageManager.shared.localizedString(for: "meditation.mindfulness.title")
        case "grounding": return LanguageManager.shared.localizedString(for: "meditation.grounding.title")
        case "visualization": return LanguageManager.shared.localizedString(for: "meditation.visualization.title")
        case "compassion": return LanguageManager.shared.localizedString(for: "meditation.compassion.title")
        case "focus-clarity": return LanguageManager.shared.localizedString(for: "meditation.focus_clarity.title")
        case "yoga-nidra": return LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.title")
        default: return title
        }
    }

    var localizedBenefit: String {
        switch meditationId {
        case "conscious-breathing": return LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.benefit")
        case "body-scan": return LanguageManager.shared.localizedString(for: "meditation.body_scan.benefit")
        case "mindfulness": return LanguageManager.shared.localizedString(for: "meditation.mindfulness.benefit")
        case "grounding": return LanguageManager.shared.localizedString(for: "meditation.grounding.benefit")
        case "visualization": return LanguageManager.shared.localizedString(for: "meditation.visualization.benefit")
        case "compassion": return LanguageManager.shared.localizedString(for: "meditation.compassion.benefit")
        case "focus-clarity": return LanguageManager.shared.localizedString(for: "meditation.focus_clarity.benefit")
        case "yoga-nidra": return LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.benefit")
        default: return benefit
        }
    }

    var detailedDescription: String {
        switch meditationId {
        case "conscious-breathing":
            return LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.detailed_description")
        case "body-scan":
            return LanguageManager.shared.localizedString(for: "meditation.body_scan.detailed_description")
        case "mindfulness":
            return LanguageManager.shared.localizedString(for: "meditation.mindfulness.detailed_description")
        case "grounding":
            return LanguageManager.shared.localizedString(for: "meditation.grounding.detailed_description")
        case "visualization":
            return LanguageManager.shared.localizedString(for: "meditation.visualization.detailed_description")
        case "compassion":
            return LanguageManager.shared.localizedString(for: "meditation.compassion.detailed_description")
        case "focus-clarity":
            return LanguageManager.shared.localizedString(for: "meditation.focus_clarity.detailed_description")
        case "yoga-nidra":
            return LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.detailed_description")
        default:
            return content.sections.first?.content ?? ""
        }
    }

    var benefits: [String] {
        switch meditationId {
        case "conscious-breathing":
            return [
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.benefit_4")
            ]
        case "body-scan":
            return [
                LanguageManager.shared.localizedString(for: "meditation.body_scan.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.body_scan.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.body_scan.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.body_scan.benefit_4")
            ]
        case "mindfulness":
            return [
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.benefit_4")
            ]
        case "grounding":
            return [
                LanguageManager.shared.localizedString(for: "meditation.grounding.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.grounding.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.grounding.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.grounding.benefit_4")
            ]
        case "visualization":
            return [
                LanguageManager.shared.localizedString(for: "meditation.visualization.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.visualization.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.visualization.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.visualization.benefit_4")
            ]
        case "compassion":
            return [
                LanguageManager.shared.localizedString(for: "meditation.compassion.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.compassion.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.compassion.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.compassion.benefit_4")
            ]
        case "focus-clarity":
            return [
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.benefit_4")
            ]
        case "yoga-nidra":
            return [
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.benefit_1"),
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.benefit_2"),
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.benefit_3"),
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.benefit_4")
            ]
        default:
            return []
        }
    }

    var scientificEvidence: [String] {
        switch meditationId {
        case "conscious-breathing":
            return [
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.evidence_3")
            ]
        case "body-scan":
            return [
                LanguageManager.shared.localizedString(for: "meditation.body_scan.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.body_scan.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.body_scan.evidence_3")
            ]
        case "mindfulness":
            return [
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.mindfulness.evidence_3")
            ]
        case "grounding":
            return [
                LanguageManager.shared.localizedString(for: "meditation.grounding.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.grounding.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.grounding.evidence_3")
            ]
        case "visualization":
            return [
                LanguageManager.shared.localizedString(for: "meditation.visualization.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.visualization.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.visualization.evidence_3")
            ]
        case "compassion":
            return [
                LanguageManager.shared.localizedString(for: "meditation.compassion.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.compassion.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.compassion.evidence_3")
            ]
        case "focus-clarity":
            return [
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.focus_clarity.evidence_3")
            ]
        case "yoga-nidra":
            return [
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.evidence_1"),
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.evidence_2"),
                LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.evidence_3")
            ]
        default:
            return [LanguageManager.shared.localizedString(for: "meditation.default.evidence")]
        }
    }

    var scientificSources: [String] {
        return [LanguageManager.shared.localizedString(for: "meditation_detail.source")]
    }

    // Keep for backward compatibility
    var scientificSource: String {
        return scientificSources.first ?? ""
    }
}

// MARK: - Conversion to Unified Instruction Steps

extension MeditationSupport {
    func toUnifiedInstructionSteps() -> [UnifiedInstructionStep] {
        guard let section = content.sections.first else { return [] }

        // Retourner les steps avec copywriting amélioré selon le type
        if let steps = section.steps {
            return enhancedSteps(for: meditationId, steps: steps)
        } else if section.affirmations != nil {
            return enhancedAffirmations()
        }

        return []
    }

    private func enhancedSteps(for meditationId: String, steps: [String]) -> [UnifiedInstructionStep] {
        switch meditationId {
        case "conscious-breathing":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_1.subtitle"),
                    icon: "figure.mind.and.body",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_2.subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_3.subtitle"),
                    icon: "nose.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_4.subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_5.subtitle"),
                    icon: "timer",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.step_5.duration")
                )
            ]

        case "body-scan":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_1.subtitle"),
                    icon: "shoeprints.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_2.subtitle"),
                    icon: "figure.walk",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_3.subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_4.subtitle"),
                    icon: "lungs.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_5.subtitle"),
                    icon: "face.smiling",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.body_scan.step_5.duration")
                )
            ]

        case "mindfulness":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_1.subtitle"),
                    icon: "figure.mind.and.body",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_2.subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_3.subtitle"),
                    icon: "brain.head.profile",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_4.subtitle"),
                    icon: "cloud.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_5.subtitle"),
                    icon: "arrow.circlepath",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.mindfulness.step_5.duration")
                )
            ]

        case "grounding":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.grounding.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.grounding.step_1.subtitle"),
                    icon: "eye.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.grounding.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.grounding.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.grounding.step_2.subtitle"),
                    icon: "hand.raised.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.grounding.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.grounding.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.grounding.step_3.subtitle"),
                    icon: "ear.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.grounding.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.grounding.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.grounding.step_4.subtitle"),
                    icon: "nose.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.grounding.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.grounding.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.grounding.step_5.subtitle"),
                    icon: "mouth.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.grounding.step_5.duration")
                )
            ]

        case "visualization":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_1.subtitle"),
                    icon: "eye.slash.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_2.subtitle"),
                    icon: "sparkles",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_3.subtitle"),
                    icon: "paintpalette.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_4.subtitle"),
                    icon: "speaker.wave.3.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_5.subtitle"),
                    icon: "hand.raised.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_5.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.visualization.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.visualization.step_6.subtitle"),
                    icon: "house.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.visualization.step_6.duration")
                )
            ]

        case "focus-clarity":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_1.subtitle"),
                    icon: "target",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_2.subtitle"),
                    icon: "eye.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_3.subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_4.subtitle"),
                    icon: "drop.fill",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.step_4.duration")
                )
            ]

        case "yoga-nidra":
            return [
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_1.subtitle"),
                    icon: "bed.double.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_1.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_2.subtitle"),
                    icon: "figure.stand",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_2.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_3.subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_3.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_4.subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_4.duration")
                ),
                UnifiedInstructionStep(
                    title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_5.subtitle"),
                    icon: "moon.zzz.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.step_5.duration")
                )
            ]

        default:
            // Fallback - convertir les steps basiques en UnifiedInstructionStep
            return steps.enumerated().map { index, step in
                UnifiedInstructionStep(
                    title: step,
                    subtitle: nil,
                    icon: "brain.head.profile",
                    color: index % 2 == 0 ? "B388FF" : "8C9EFF",
                    estimatedDuration: nil
                )
            }
        }
    }

    private func enhancedAffirmations() -> [UnifiedInstructionStep] {
        // Pour les affirmations (compassion)
        return [
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_1.title"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_1.subtitle"),
                icon: "hand.raised.fill",
                color: "B388FF",
                estimatedDuration: "15 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_1"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_2.subtitle"),
                icon: "heart.fill",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_2"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_3.subtitle"),
                icon: "star.fill",
                color: "B388FF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_3"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_4.subtitle"),
                icon: "sparkles",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_4"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_5.subtitle"),
                icon: "wind",
                color: "B388FF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_5"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_6.subtitle"),
                icon: "hands.and.sparkles.fill",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.affirmation_6"),
                subtitle: LanguageManager.shared.localizedString(for: "meditation.compassion.enhanced_step_7.subtitle"),
                icon: "face.smiling.fill",
                color: "B388FF",
                estimatedDuration: "30 sec"
            )
        ]
    }
}
