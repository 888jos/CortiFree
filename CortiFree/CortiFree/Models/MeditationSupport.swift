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

struct MeditationSupport: Identifiable {
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
                    affirmations: [
                        "Je mérite amour et compassion",
                        "Je suis assez, tel que je suis",
                        "Je m'accueille avec douceur",
                        "Je me pardonne mes erreurs",
                        "Je suis digne de bienveillance",
                        "Je prends soin de moi avec tendresse"
                    ]
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
        case "conscious-breathing": return NSLocalizedString("meditation.conscious_breathing.title", comment: "")
        case "body-scan": return NSLocalizedString("meditation.body_scan.title", comment: "")
        case "mindfulness": return NSLocalizedString("meditation.mindfulness.title", comment: "")
        case "grounding": return NSLocalizedString("meditation.grounding.title", comment: "")
        case "visualization": return NSLocalizedString("meditation.visualization.title", comment: "")
        case "compassion": return NSLocalizedString("meditation.compassion.title", comment: "")
        case "focus-clarity": return NSLocalizedString("meditation.focus_clarity.title", comment: "")
        case "yoga-nidra": return NSLocalizedString("meditation.yoga_nidra.title", comment: "")
        default: return title
        }
    }

    var localizedBenefit: String {
        switch meditationId {
        case "conscious-breathing": return NSLocalizedString("meditation.conscious_breathing.benefit", comment: "")
        case "body-scan": return NSLocalizedString("meditation.body_scan.benefit", comment: "")
        case "mindfulness": return NSLocalizedString("meditation.mindfulness.benefit", comment: "")
        case "grounding": return NSLocalizedString("meditation.grounding.benefit", comment: "")
        case "visualization": return NSLocalizedString("meditation.visualization.benefit", comment: "")
        case "compassion": return NSLocalizedString("meditation.compassion.benefit", comment: "")
        case "focus-clarity": return NSLocalizedString("meditation.focus_clarity.benefit", comment: "")
        case "yoga-nidra": return NSLocalizedString("meditation.yoga_nidra.benefit", comment: "")
        default: return benefit
        }
    }

    var detailedDescription: String {
        switch meditationId {
        case "conscious-breathing":
            return NSLocalizedString("meditation.conscious_breathing.detailed_description", comment: "")
        case "body-scan":
            return NSLocalizedString("meditation.body_scan.detailed_description", comment: "")
        case "mindfulness":
            return NSLocalizedString("meditation.mindfulness.detailed_description", comment: "")
        case "grounding":
            return NSLocalizedString("meditation.grounding.detailed_description", comment: "")
        case "visualization":
            return NSLocalizedString("meditation.visualization.detailed_description", comment: "")
        case "compassion":
            return NSLocalizedString("meditation.compassion.detailed_description", comment: "")
        case "focus-clarity":
            return NSLocalizedString("meditation.focus_clarity.detailed_description", comment: "")
        case "yoga-nidra":
            return NSLocalizedString("meditation.yoga_nidra.detailed_description", comment: "")
        default:
            return content.sections.first?.content ?? ""
        }
    }

    var benefits: [String] {
        switch meditationId {
        case "conscious-breathing":
            return [
                NSLocalizedString("meditation.conscious_breathing.benefit_1", comment: ""),
                NSLocalizedString("meditation.conscious_breathing.benefit_2", comment: ""),
                NSLocalizedString("meditation.conscious_breathing.benefit_3", comment: ""),
                NSLocalizedString("meditation.conscious_breathing.benefit_4", comment: "")
            ]
        case "body-scan":
            return [
                NSLocalizedString("meditation.body_scan.benefit_1", comment: ""),
                NSLocalizedString("meditation.body_scan.benefit_2", comment: ""),
                NSLocalizedString("meditation.body_scan.benefit_3", comment: ""),
                NSLocalizedString("meditation.body_scan.benefit_4", comment: "")
            ]
        case "mindfulness":
            return [
                NSLocalizedString("meditation.mindfulness.benefit_1", comment: ""),
                NSLocalizedString("meditation.mindfulness.benefit_2", comment: ""),
                NSLocalizedString("meditation.mindfulness.benefit_3", comment: ""),
                NSLocalizedString("meditation.mindfulness.benefit_4", comment: "")
            ]
        case "grounding":
            return [
                NSLocalizedString("meditation.grounding.benefit_1", comment: ""),
                NSLocalizedString("meditation.grounding.benefit_2", comment: ""),
                NSLocalizedString("meditation.grounding.benefit_3", comment: ""),
                NSLocalizedString("meditation.grounding.benefit_4", comment: "")
            ]
        case "visualization":
            return [
                NSLocalizedString("meditation.visualization.benefit_1", comment: ""),
                NSLocalizedString("meditation.visualization.benefit_2", comment: ""),
                NSLocalizedString("meditation.visualization.benefit_3", comment: ""),
                NSLocalizedString("meditation.visualization.benefit_4", comment: "")
            ]
        case "compassion":
            return [
                NSLocalizedString("meditation.compassion.benefit_1", comment: ""),
                NSLocalizedString("meditation.compassion.benefit_2", comment: ""),
                NSLocalizedString("meditation.compassion.benefit_3", comment: ""),
                NSLocalizedString("meditation.compassion.benefit_4", comment: "")
            ]
        case "focus-clarity":
            return [
                NSLocalizedString("meditation.focus_clarity.benefit_1", comment: ""),
                NSLocalizedString("meditation.focus_clarity.benefit_2", comment: ""),
                NSLocalizedString("meditation.focus_clarity.benefit_3", comment: ""),
                NSLocalizedString("meditation.focus_clarity.benefit_4", comment: "")
            ]
        case "yoga-nidra":
            return [
                NSLocalizedString("meditation.yoga_nidra.benefit_1", comment: ""),
                NSLocalizedString("meditation.yoga_nidra.benefit_2", comment: ""),
                NSLocalizedString("meditation.yoga_nidra.benefit_3", comment: ""),
                NSLocalizedString("meditation.yoga_nidra.benefit_4", comment: "")
            ]
        default:
            return []
        }
    }

    var scientificEvidence: [String] {
        switch meditationId {
        case "conscious-breathing":
            return [
                NSLocalizedString("meditation.conscious_breathing.evidence_1", comment: ""),
                NSLocalizedString("meditation.conscious_breathing.evidence_2", comment: ""),
                NSLocalizedString("meditation.conscious_breathing.evidence_3", comment: "")
            ]
        case "body-scan":
            return [
                NSLocalizedString("meditation.body_scan.evidence_1", comment: ""),
                NSLocalizedString("meditation.body_scan.evidence_2", comment: ""),
                NSLocalizedString("meditation.body_scan.evidence_3", comment: "")
            ]
        case "mindfulness":
            return [
                NSLocalizedString("meditation.mindfulness.evidence_1", comment: ""),
                NSLocalizedString("meditation.mindfulness.evidence_2", comment: ""),
                NSLocalizedString("meditation.mindfulness.evidence_3", comment: "")
            ]
        case "grounding":
            return [
                NSLocalizedString("meditation.grounding.evidence_1", comment: ""),
                NSLocalizedString("meditation.grounding.evidence_2", comment: ""),
                NSLocalizedString("meditation.grounding.evidence_3", comment: "")
            ]
        case "visualization":
            return [
                NSLocalizedString("meditation.visualization.evidence_1", comment: ""),
                NSLocalizedString("meditation.visualization.evidence_2", comment: ""),
                NSLocalizedString("meditation.visualization.evidence_3", comment: "")
            ]
        case "compassion":
            return [
                NSLocalizedString("meditation.compassion.evidence_1", comment: ""),
                NSLocalizedString("meditation.compassion.evidence_2", comment: ""),
                NSLocalizedString("meditation.compassion.evidence_3", comment: "")
            ]
        case "focus-clarity":
            return [
                NSLocalizedString("meditation.focus_clarity.evidence_1", comment: ""),
                NSLocalizedString("meditation.focus_clarity.evidence_2", comment: ""),
                NSLocalizedString("meditation.focus_clarity.evidence_3", comment: "")
            ]
        case "yoga-nidra":
            return [
                NSLocalizedString("meditation.yoga_nidra.evidence_1", comment: ""),
                NSLocalizedString("meditation.yoga_nidra.evidence_2", comment: ""),
                NSLocalizedString("meditation.yoga_nidra.evidence_3", comment: "")
            ]
        default:
            return [NSLocalizedString("meditation.default.evidence", comment: "")]
        }
    }

    var scientificSource: String {
        switch meditationId {
        case "conscious-breathing": return NSLocalizedString("meditation.conscious_breathing.source", comment: "")
        case "body-scan": return NSLocalizedString("meditation.body_scan.source", comment: "")
        case "mindfulness": return NSLocalizedString("meditation.mindfulness.source", comment: "")
        case "grounding": return NSLocalizedString("meditation.grounding.source", comment: "")
        case "visualization": return NSLocalizedString("meditation.visualization.source", comment: "")
        case "compassion": return NSLocalizedString("meditation.compassion.source", comment: "")
        case "focus-clarity": return NSLocalizedString("meditation.focus_clarity.source", comment: "")
        case "yoga-nidra": return NSLocalizedString("meditation.yoga_nidra.source", comment: "")
        default: return NSLocalizedString("meditation.default.source", comment: "")
        }
    }
}

// MARK: - Conversion to Unified Instruction Steps

extension MeditationSupport {
    func toUnifiedInstructionSteps() -> [UnifiedInstructionStep] {
        guard let section = content.sections.first else { return [] }

        // Retourner les steps avec copywriting amélioré selon le type
        if let steps = section.steps {
            return enhancedSteps(for: meditationId, steps: steps)
        } else if let affirmations = section.affirmations {
            return enhancedAffirmations(affirmations: affirmations)
        }

        return []
    }

    private func enhancedSteps(for meditationId: String, steps: [String]) -> [UnifiedInstructionStep] {
        switch meditationId {
        case "conscious-breathing":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.conscious_breathing.step_1.title", comment: "Conscious breathing step 1 title"),
                    subtitle: NSLocalizedString("meditation.conscious_breathing.step_1.subtitle", comment: "Conscious breathing step 1 subtitle"),
                    icon: "figure.mind.and.body",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.conscious_breathing.step_1.duration", comment: "Conscious breathing step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.conscious_breathing.step_2.title", comment: "Conscious breathing step 2 title"),
                    subtitle: NSLocalizedString("meditation.conscious_breathing.step_2.subtitle", comment: "Conscious breathing step 2 subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.conscious_breathing.step_2.duration", comment: "Conscious breathing step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.conscious_breathing.step_3.title", comment: "Conscious breathing step 3 title"),
                    subtitle: NSLocalizedString("meditation.conscious_breathing.step_3.subtitle", comment: "Conscious breathing step 3 subtitle"),
                    icon: "nose.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.conscious_breathing.step_3.duration", comment: "Conscious breathing step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.conscious_breathing.step_4.title", comment: "Conscious breathing step 4 title"),
                    subtitle: NSLocalizedString("meditation.conscious_breathing.step_4.subtitle", comment: "Conscious breathing step 4 subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.conscious_breathing.step_4.duration", comment: "Conscious breathing step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.conscious_breathing.step_5.title", comment: "Conscious breathing step 5 title"),
                    subtitle: NSLocalizedString("meditation.conscious_breathing.step_5.subtitle", comment: "Conscious breathing step 5 subtitle"),
                    icon: "timer",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.conscious_breathing.step_5.duration", comment: "Conscious breathing step 5 duration")
                )
            ]

        case "body-scan":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.body_scan.step_1.title", comment: "Meditation body scan step 1 title"),
                    subtitle: NSLocalizedString("meditation.body_scan.step_1.subtitle", comment: "Meditation body scan step 1 subtitle"),
                    icon: "shoeprints.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.body_scan.step_1.duration", comment: "Meditation body scan step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.body_scan.step_2.title", comment: "Meditation body scan step 2 title"),
                    subtitle: NSLocalizedString("meditation.body_scan.step_2.subtitle", comment: "Meditation body scan step 2 subtitle"),
                    icon: "figure.walk",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.body_scan.step_2.duration", comment: "Meditation body scan step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.body_scan.step_3.title", comment: "Meditation body scan step 3 title"),
                    subtitle: NSLocalizedString("meditation.body_scan.step_3.subtitle", comment: "Meditation body scan step 3 subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.body_scan.step_3.duration", comment: "Meditation body scan step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.body_scan.step_4.title", comment: "Meditation body scan step 4 title"),
                    subtitle: NSLocalizedString("meditation.body_scan.step_4.subtitle", comment: "Meditation body scan step 4 subtitle"),
                    icon: "lungs.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.body_scan.step_4.duration", comment: "Meditation body scan step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.body_scan.step_5.title", comment: "Meditation body scan step 5 title"),
                    subtitle: NSLocalizedString("meditation.body_scan.step_5.subtitle", comment: "Meditation body scan step 5 subtitle"),
                    icon: "face.smiling",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.body_scan.step_5.duration", comment: "Meditation body scan step 5 duration")
                )
            ]

        case "mindfulness":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.mindfulness.step_1.title", comment: "Mindfulness step 1 title"),
                    subtitle: NSLocalizedString("meditation.mindfulness.step_1.subtitle", comment: "Mindfulness step 1 subtitle"),
                    icon: "figure.mind.and.body",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.mindfulness.step_1.duration", comment: "Mindfulness step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.mindfulness.step_2.title", comment: "Mindfulness step 2 title"),
                    subtitle: NSLocalizedString("meditation.mindfulness.step_2.subtitle", comment: "Mindfulness step 2 subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.mindfulness.step_2.duration", comment: "Mindfulness step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.mindfulness.step_3.title", comment: "Mindfulness step 3 title"),
                    subtitle: NSLocalizedString("meditation.mindfulness.step_3.subtitle", comment: "Mindfulness step 3 subtitle"),
                    icon: "brain.head.profile",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.mindfulness.step_3.duration", comment: "Mindfulness step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.mindfulness.step_4.title", comment: "Mindfulness step 4 title"),
                    subtitle: NSLocalizedString("meditation.mindfulness.step_4.subtitle", comment: "Mindfulness step 4 subtitle"),
                    icon: "cloud.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.mindfulness.step_4.duration", comment: "Mindfulness step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.mindfulness.step_5.title", comment: "Mindfulness step 5 title"),
                    subtitle: NSLocalizedString("meditation.mindfulness.step_5.subtitle", comment: "Mindfulness step 5 subtitle"),
                    icon: "arrow.circlepath",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.mindfulness.step_5.duration", comment: "Mindfulness step 5 duration")
                )
            ]

        case "grounding":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.grounding.step_1.title", comment: "Meditation grounding step 1 title"),
                    subtitle: NSLocalizedString("meditation.grounding.step_1.subtitle", comment: "Meditation grounding step 1 subtitle"),
                    icon: "eye.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.grounding.step_1.duration", comment: "Meditation grounding step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.grounding.step_2.title", comment: "Meditation grounding step 2 title"),
                    subtitle: NSLocalizedString("meditation.grounding.step_2.subtitle", comment: "Meditation grounding step 2 subtitle"),
                    icon: "hand.raised.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.grounding.step_2.duration", comment: "Meditation grounding step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.grounding.step_3.title", comment: "Meditation grounding step 3 title"),
                    subtitle: NSLocalizedString("meditation.grounding.step_3.subtitle", comment: "Meditation grounding step 3 subtitle"),
                    icon: "ear.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.grounding.step_3.duration", comment: "Meditation grounding step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.grounding.step_4.title", comment: "Meditation grounding step 4 title"),
                    subtitle: NSLocalizedString("meditation.grounding.step_4.subtitle", comment: "Meditation grounding step 4 subtitle"),
                    icon: "nose.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.grounding.step_4.duration", comment: "Meditation grounding step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.grounding.step_5.title", comment: "Meditation grounding step 5 title"),
                    subtitle: NSLocalizedString("meditation.grounding.step_5.subtitle", comment: "Meditation grounding step 5 subtitle"),
                    icon: "mouth.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.grounding.step_5.duration", comment: "Meditation grounding step 5 duration")
                )
            ]

        case "visualization":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_1.title", comment: "Visualization step 1 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_1.subtitle", comment: "Visualization step 1 subtitle"),
                    icon: "eye.slash.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_1.duration", comment: "Visualization step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_2.title", comment: "Visualization step 2 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_2.subtitle", comment: "Visualization step 2 subtitle"),
                    icon: "sparkles",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_2.duration", comment: "Visualization step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_3.title", comment: "Visualization step 3 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_3.subtitle", comment: "Visualization step 3 subtitle"),
                    icon: "paintpalette.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_3.duration", comment: "Visualization step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_4.title", comment: "Visualization step 4 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_4.subtitle", comment: "Visualization step 4 subtitle"),
                    icon: "speaker.wave.3.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_4.duration", comment: "Visualization step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_5.title", comment: "Visualization step 5 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_5.subtitle", comment: "Visualization step 5 subtitle"),
                    icon: "hand.raised.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_5.duration", comment: "Visualization step 5 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.visualization.step_6.title", comment: "Visualization step 6 title"),
                    subtitle: NSLocalizedString("meditation.visualization.step_6.subtitle", comment: "Visualization step 6 subtitle"),
                    icon: "house.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.visualization.step_6.duration", comment: "Visualization step 6 duration")
                )
            ]

        case "focus-clarity":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.focus_clarity.step_1.title", comment: "Focus clarity step 1 title"),
                    subtitle: NSLocalizedString("meditation.focus_clarity.step_1.subtitle", comment: "Focus clarity step 1 subtitle"),
                    icon: "target",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.focus_clarity.step_1.duration", comment: "Focus clarity step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.focus_clarity.step_2.title", comment: "Focus clarity step 2 title"),
                    subtitle: NSLocalizedString("meditation.focus_clarity.step_2.subtitle", comment: "Focus clarity step 2 subtitle"),
                    icon: "eye.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.focus_clarity.step_2.duration", comment: "Focus clarity step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.focus_clarity.step_3.title", comment: "Focus clarity step 3 title"),
                    subtitle: NSLocalizedString("meditation.focus_clarity.step_3.subtitle", comment: "Focus clarity step 3 subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.focus_clarity.step_3.duration", comment: "Focus clarity step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.focus_clarity.step_4.title", comment: "Focus clarity step 4 title"),
                    subtitle: NSLocalizedString("meditation.focus_clarity.step_4.subtitle", comment: "Focus clarity step 4 subtitle"),
                    icon: "drop.fill",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.focus_clarity.step_4.duration", comment: "Focus clarity step 4 duration")
                )
            ]

        case "yoga-nidra":
            return [
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.yoga_nidra.step_1.title", comment: "Yoga nidra step 1 title"),
                    subtitle: NSLocalizedString("meditation.yoga_nidra.step_1.subtitle", comment: "Yoga nidra step 1 subtitle"),
                    icon: "bed.double.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.yoga_nidra.step_1.duration", comment: "Yoga nidra step 1 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.yoga_nidra.step_2.title", comment: "Yoga nidra step 2 title"),
                    subtitle: NSLocalizedString("meditation.yoga_nidra.step_2.subtitle", comment: "Yoga nidra step 2 subtitle"),
                    icon: "figure.stand",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.yoga_nidra.step_2.duration", comment: "Yoga nidra step 2 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.yoga_nidra.step_3.title", comment: "Yoga nidra step 3 title"),
                    subtitle: NSLocalizedString("meditation.yoga_nidra.step_3.subtitle", comment: "Yoga nidra step 3 subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.yoga_nidra.step_3.duration", comment: "Yoga nidra step 3 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.yoga_nidra.step_4.title", comment: "Yoga nidra step 4 title"),
                    subtitle: NSLocalizedString("meditation.yoga_nidra.step_4.subtitle", comment: "Yoga nidra step 4 subtitle"),
                    icon: "wind",
                    color: "8C9EFF",
                    estimatedDuration: NSLocalizedString("meditation.yoga_nidra.step_4.duration", comment: "Yoga nidra step 4 duration")
                ),
                UnifiedInstructionStep(
                    title: NSLocalizedString("meditation.yoga_nidra.step_5.title", comment: "Yoga nidra step 5 title"),
                    subtitle: NSLocalizedString("meditation.yoga_nidra.step_5.subtitle", comment: "Yoga nidra step 5 subtitle"),
                    icon: "moon.zzz.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("meditation.yoga_nidra.step_5.duration", comment: "Yoga nidra step 5 duration")
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

    private func enhancedAffirmations(affirmations: [String]) -> [UnifiedInstructionStep] {
        // Pour les affirmations (compassion)
        return [
            UnifiedInstructionStep(
                title: "Place ta main sur ton cœur",
                subtitle: "Sens sa chaleur, son rythme",
                icon: "hand.raised.fill",
                color: "B388FF",
                estimatedDuration: "15 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[0],
                subtitle: "Répète 3 fois, ressens vraiment chaque mot",
                icon: "heart.fill",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[1],
                subtitle: "Laisse cette vérité entrer en toi",
                icon: "star.fill",
                color: "B388FF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[2],
                subtitle: "Sens la douceur de ces mots",
                icon: "sparkles",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[3],
                subtitle: "Respire avec bienveillance",
                icon: "wind",
                color: "B388FF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[4],
                subtitle: "Tu es digne de tout l'amour du monde",
                icon: "hands.and.sparkles.fill",
                color: "8C9EFF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: affirmations[5],
                subtitle: "Termine en douceur, garde cette chaleur en toi",
                icon: "face.smiling.fill",
                color: "B388FF",
                estimatedDuration: "30 sec"
            )
        ]
    }
}
