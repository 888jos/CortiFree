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

        // Body Scan express - Instructions
        MeditationSupport(
            meditationId: "body-scan",
            supportType: .instructions,
            title: "Body Scan express",
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

        // Mindfulness de base - Guide
        MeditationSupport(
            meditationId: "mindfulness",
            supportType: .guide,
            title: "Mindfulness de base",
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

        // Ancrage corporel / Grounding - Guide
        MeditationSupport(
            meditationId: "grounding",
            supportType: .guide,
            title: "Ancrage corporel / Grounding",
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

        // Méditation focus/clarté - Tracker
        MeditationSupport(
            meditationId: "focus-clarity",
            supportType: .tracker,
            title: "Méditation focus/clarté",
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

        // Méditation sommeil / Yoga Nidra - Guide
        MeditationSupport(
            meditationId: "yoga-nidra",
            supportType: .guide,
            title: "Méditation sommeil / Yoga Nidra",
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
