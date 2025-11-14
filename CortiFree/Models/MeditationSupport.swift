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
        // Scan Corporel - Instructions détaillées
        MeditationSupport(
            meditationId: "body-scan",
            supportType: .instructions,
            title: "Instructions pour le Scan Corporel",
            benefit: "Reconnectez-vous à votre corps et relâchez les tensions physiques accumulées.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Préparation",
                    content: "Installez-vous confortablement, allongé ou assis. Fermez les yeux et prenez quelques respirations profondes.",
                    tips: [
                        "Choisissez un endroit calme",
                        "Utilisez un coussin ou matelas confortable",
                        "Assurez-vous de ne pas être dérangé"
                    ],
                    prompts: nil,
                    steps: [
                        "Allongez-vous sur le dos, bras le long du corps",
                        "Prenez 3 respirations profondes",
                        "Portez votre attention sur votre respiration naturelle"
                    ],
                    affirmations: nil
                ),
                SupportSection(
                    title: "Le Scan",
                    content: "Parcourez mentalement chaque partie de votre corps, des pieds à la tête.",
                    tips: [
                        "Ne jugez pas les sensations",
                        "Observez simplement ce qui est présent",
                        "Prenez votre temps"
                    ],
                    prompts: nil,
                    steps: [
                        "Commencez par les orteils du pied droit",
                        "Remontez vers la cheville, le mollet, le genou",
                        "Continuez vers la cuisse, puis changez de jambe",
                        "Scannez le bassin, l'abdomen, la poitrine",
                        "Passez aux mains, bras, épaules",
                        "Terminez par le cou et la tête"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Gratitude - Journal de réflexion
        MeditationSupport(
            meditationId: "gratitude",
            supportType: .journal,
            title: "Journal de Gratitude",
            benefit: "Cultivez un état d'esprit positif et appréciez les petits bonheurs de la vie.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Réflexion Quotidienne",
                    content: "Prenez un moment pour noter ce pour quoi vous êtes reconnaissant aujourd'hui.",
                    tips: [
                        "Soyez spécifique dans vos remerciements",
                        "Incluez de petites choses du quotidien",
                        "Ressentez vraiment la gratitude en écrivant"
                    ],
                    prompts: [
                        "Aujourd'hui, je suis reconnaissant pour...",
                        "Une personne qui a rendu ma journée meilleure est...",
                        "Un moment simple qui m'a apporté de la joie...",
                        "Une difficulté qui m'a appris quelque chose...",
                        "Une qualité que j'apprécie chez moi..."
                    ],
                    steps: nil,
                    affirmations: nil
                )
            ])
        ),

        // Pleine Conscience - Guide avec conseils
        MeditationSupport(
            meditationId: "mindfulness",
            supportType: .guide,
            title: "Guide de Pleine Conscience",
            benefit: "Vivez pleinement le moment présent et réduisez le stress mental.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Qu'est-ce que la Pleine Conscience ?",
                    content: "La pleine conscience est l'art d'être pleinement présent dans l'instant, sans jugement.",
                    tips: [
                        "Commencez par de courtes sessions (5-10 min)",
                        "Pratiquez quotidiennement, même brièvement",
                        "Soyez bienveillant envers vous-même"
                    ],
                    prompts: nil,
                    steps: [
                        "Trouvez une position confortable",
                        "Portez attention à votre respiration",
                        "Quand l'esprit s'égare, revenez doucement à la respiration",
                        "Observez vos pensées sans vous y attacher",
                        "Terminez en ouvrant lentement les yeux"
                    ],
                    affirmations: nil
                ),
                SupportSection(
                    title: "Intégration Quotidienne",
                    content: "Comment pratiquer la pleine conscience dans votre vie de tous les jours.",
                    tips: [
                        "Mangez en pleine conscience",
                        "Marchez consciemment",
                        "Écoutez activement lors des conversations",
                        "Faites une pause avant de réagir"
                    ],
                    prompts: nil,
                    steps: nil,
                    affirmations: nil
                )
            ])
        ),

        // Visualisation - Guide visuel
        MeditationSupport(
            meditationId: "visualization",
            supportType: .visualGuide,
            title: "Guide de Visualisation Positive",
            benefit: "Créez un espace mental apaisant et stimulez votre imagination positive.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Créer Votre Image Mentale",
                    content: "La visualisation utilise l'imagination pour créer des images mentales apaisantes et positives.",
                    tips: [
                        "Engagez tous vos sens",
                        "Rendez l'image aussi vivide que possible",
                        "Choisissez des scènes qui vous apaisent"
                    ],
                    prompts: nil,
                    steps: [
                        "Fermez les yeux et respirez profondément",
                        "Imaginez un lieu qui vous apaise (plage, forêt, montagne...)",
                        "Visualisez les détails : couleurs, sons, odeurs",
                        "Ressentez les sensations : température, texture",
                        "Restez dans cette image 5-10 minutes",
                        "Revenez doucement au présent"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Auto-Compassion - Affirmations
        MeditationSupport(
            meditationId: "compassion",
            supportType: .affirmations,
            title: "Affirmations d'Auto-Compassion",
            benefit: "Développez une relation bienveillante avec vous-même et renforcez votre estime personnelle.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Cultiver la Bienveillance",
                    content: "Répétez ces affirmations pour développer une relation plus douce avec vous-même.",
                    tips: [
                        "Répétez chaque affirmation 3 fois",
                        "Ressentez vraiment les mots",
                        "Placez votre main sur votre cœur"
                    ],
                    prompts: nil,
                    steps: nil,
                    affirmations: [
                        "Je mérite amour et compassion",
                        "Je suis digne de bienveillance",
                        "Mes imperfections font partie de mon humanité",
                        "Je m'accueille avec douceur",
                        "Je suis assez, tel que je suis",
                        "Je me pardonne mes erreurs",
                        "Je prends soin de moi avec tendresse"
                    ]
                )
            ])
        ),

        // Clarté - Tracker
        MeditationSupport(
            meditationId: "clarity",
            supportType: .tracker,
            title: "Suivi de Clarté Mentale",
            benefit: "Organisez vos pensées et gagnez en clarté pour mieux décider et agir.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Évaluation",
                    content: "Suivez votre progression vers une plus grande clarté mentale.",
                    tips: [
                        "Notez votre niveau de clarté avant et après",
                        "Identifiez les pensées récurrentes",
                        "Observez les patterns sur plusieurs jours"
                    ],
                    prompts: [
                        "Avant la méditation, mon esprit est... (agité/calme/confus/clair)",
                        "Les pensées dominantes sont...",
                        "Après la méditation, je me sens...",
                        "J'ai gagné en clarté sur...",
                        "Demain, je vais porter attention à..."
                    ],
                    steps: nil,
                    affirmations: nil
                )
            ])
        ),

        // Marche Méditative - Instructions
        MeditationSupport(
            meditationId: "walking",
            supportType: .instructions,
            title: "Instructions pour la Marche Méditative",
            benefit: "Combinez mouvement et méditation pour ancrer votre présence dans l'instant.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Préparation",
                    content: "Trouvez un espace où vous pouvez marcher sans interruption pendant 10-15 minutes.",
                    tips: [
                        "Choisissez un endroit calme",
                        "Marchez lentement, plus lentement que d'habitude",
                        "Portez des chaussures confortables ou marchez pieds nus"
                    ],
                    prompts: nil,
                    steps: [
                        "Tenez-vous debout, pieds écartés à largeur des hanches",
                        "Prenez conscience de votre posture",
                        "Commencez à marcher très lentement",
                        "Portez attention à chaque mouvement du pied",
                        "Observez : lever le pied, avancer, poser le talon, dérouler jusqu'aux orteils",
                        "Respirez naturellement",
                        "Si l'esprit s'égare, revenez aux sensations de la marche"
                    ],
                    affirmations: nil
                )
            ])
        ),

        // Ancrage - Guide
        MeditationSupport(
            meditationId: "grounding",
            supportType: .guide,
            title: "Guide d'Ancrage",
            benefit: "Retrouvez stabilité et connexion au présent dans les moments d'anxiété ou de stress.",
            content: MeditationSupportContent(sections: [
                SupportSection(
                    title: "Technique 5-4-3-2-1",
                    content: "Une méthode puissante pour vous reconnecter au moment présent.",
                    tips: [
                        "Prenez votre temps avec chaque sens",
                        "Dites à voix haute ou mentalement",
                        "Respirez profondément entre chaque étape"
                    ],
                    prompts: nil,
                    steps: [
                        "5 choses que vous VOYEZ autour de vous",
                        "4 choses que vous pouvez TOUCHER",
                        "3 choses que vous ENTENDEZ",
                        "2 choses que vous SENTEZ (odeurs)",
                        "1 chose que vous pouvez GOÛTER"
                    ],
                    affirmations: nil
                ),
                SupportSection(
                    title: "Ancrage par les Pieds",
                    content: "Connectez-vous à la terre pour retrouver stabilité et calme.",
                    tips: [
                        "Pratiquez debout ou assis",
                        "Imaginez des racines qui vous relient à la terre"
                    ],
                    prompts: nil,
                    steps: [
                        "Sentez vos pieds en contact avec le sol",
                        "Visualisez des racines qui partent de vos pieds",
                        "Ces racines s'enfoncent profondément dans la terre",
                        "Ressentez la stabilité et le soutien de la terre"
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
