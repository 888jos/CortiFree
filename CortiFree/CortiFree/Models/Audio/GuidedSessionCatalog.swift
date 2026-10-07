//
//  GuidedSessionCatalog.swift
//  CortiFree
//
//  Catalogue of guided audio sessions focused on stress & cortisol.
//  Narration scripts live in Resources/Narration/narration_<lang>.json (fr, en).
//

import SwiftUI

enum GuidedSessionCatalog {

    // MARK: - Lookup

    static func session(id: String) -> GuidedSession? {
        all.first { $0.id == id }
    }

    static func sessions(in category: AudioSessionCategory) -> [GuidedSession] {
        all.filter { $0.category == category }
    }

    /// Hand-picked sessions for the Library "Quick start" carousel.
    static var featured: [GuidedSession] {
        ["sos-reset-3", "sos-cortisol-drop-5", "sleep-wind-down-10", "work-desk-reset-3", "anxiety-grounding-54321-6", "morning-intention-7"]
            .compactMap(session(id:))
    }

    /// Maps the legacy meditation ids (Exercise.meditations / MeditationSupport / routines /
    /// anti-stress flow) to audio sessions, so nothing points to missing mp3 files anymore.
    static func sessionID(forLegacyID legacyID: String) -> String? {
        switch legacyID {
        case "conscious-breathing": return "focus-single-point-6"
        case "body-scan": return "body-scan-10"
        case "mindfulness": return "anxiety-leaves-stream-8"
        case "grounding": return "anxiety-grounding-54321-6"
        case "visualization": return "sos-safe-place-7"
        case "compassion": return "compassion-loving-kindness-10"
        case "focus-clarity": return "focus-mindful-breath-12"
        case "yoga-nidra": return "body-yoga-nidra-15"
        case "meditation-2-min": return "sos-reset-3"
        default: return session(id: legacyID)?.id
        }
    }

    static func session(forLegacyID legacyID: String) -> GuidedSession? {
        sessionID(forLegacyID: legacyID).flatMap(session(id:))
    }

    // MARK: - Builder

    private static func make(
        _ id: String,
        _ category: AudioSessionCategory,
        _ minutes: Int,
        title: LocalizedText,
        subtitle: LocalizedText,
        symbol: String,
        image: String? = nil,
        colors: [Color]? = nil,
        ambience: AudioAmbience?
    ) -> GuidedSession {
        GuidedSession(
            id: id,
            title: title,
            subtitle: subtitle,
            category: category,
            durationMinutes: minutes,
            isPremium: false, // App is behind a hard paywall: everything unlocked once subscribed.
            artwork: SessionArtwork(symbol: symbol, colors: colors ?? category.colors, imageName: image),
            defaultAmbience: ambience,
            remoteAudioURL: nil
        )
    }

    private typealias T = LocalizedText

    // MARK: - Catalogue (30 sessions)

    static let all: [GuidedSession] = [

        // MARK: Stress SOS
        make("sos-reset-3", .stressSOS, 3,
             title: T(fr: "Reset express", en: "Quick reset", de: "Schneller Reset", es: "Reinicio exprés", ja: "クイックリセット", ko: "빠른 리셋"),
             subtitle: T(fr: "Trois souffles pour couper la montée de stress", en: "Three breaths to cut a stress spike", de: "Drei Atemzüge gegen akuten Stress", es: "Tres respiraciones para frenar el estrés", ja: "3回の呼吸でストレスの波を断つ", ko: "세 번의 호흡으로 스트레스 끊어내기"),
             symbol: "bolt.heart.fill", image: "situation_tendu", ambience: nil),
        make("sos-cortisol-drop-5", .stressSOS, 5,
             title: T(fr: "Faire baisser le cortisol", en: "Lower your cortisol", de: "Cortisol senken", es: "Baja tu cortisol", ja: "コルチゾールを下げる", ko: "코르티솔 낮추기"),
             subtitle: T(fr: "L'expiration longue qui dit à ton corps : tu es en sécurité", en: "The long exhale that tells your body it's safe", de: "Langes Ausatmen signalisiert: Du bist sicher", es: "La exhalación larga que le dice a tu cuerpo que está a salvo", ja: "長い吐く息がからだに安心を伝える", ko: "긴 날숨으로 몸에 안전하다고 알려주기"),
             symbol: "waveform.path.ecg", image: "routine_stress", ambience: .ocean),
        make("sos-safe-place-7", .stressSOS, 7,
             title: T(fr: "Ton refuge intérieur", en: "Your inner refuge", de: "Dein innerer Zufluchtsort", es: "Tu refugio interior", ja: "心の避難所", ko: "내면의 안식처"),
             subtitle: T(fr: "Visualise un lieu sûr et ancre-le pour y revenir", en: "Picture a safe place and anchor it to return anytime", de: "Stell dir einen sicheren Ort vor und verankere ihn", es: "Visualiza un lugar seguro y ánclalo para volver", ja: "安心できる場所を思い描き、いつでも戻れるように", ko: "안전한 장소를 떠올리고 언제든 돌아올 수 있게"),
             symbol: "sparkles", image: "meditation_03", ambience: .stream),
        make("sos-panic-anchor-4", .stressSOS, 4,
             title: T(fr: "Ancre anti-panique", en: "Panic anchor", de: "Anker bei Panik", es: "Ancla antipánico", ja: "パニックのいかり", ko: "공황 닻 내리기"),
             subtitle: T(fr: "Laisser passer la vague, les pieds bien ancrés", en: "Let the wave pass with your feet on the ground", de: "Die Welle vorbeiziehen lassen, fest am Boden", es: "Deja pasar la ola con los pies en el suelo", ja: "足を床につけて、波が過ぎるのを待つ", ko: "발을 땅에 딛고 파도가 지나가게 두기"),
             symbol: "figure.stand", image: "situation_stresse", ambience: nil),

        // MARK: Work break
        make("work-desk-reset-3", .workBreak, 3,
             title: T(fr: "Pause au bureau", en: "Desk reset", de: "Schreibtisch-Reset", es: "Pausa en el escritorio", ja: "デスクでリセット", ko: "책상 앞 리셋"),
             subtitle: T(fr: "Lever les yeux de l'écran et relâcher la nuque", en: "Look away from the screen and release your neck", de: "Weg vom Bildschirm, Nacken lockern", es: "Aparta la vista de la pantalla y suelta el cuello", ja: "画面から目を離し、首をゆるめる", ko: "화면에서 눈을 떼고 목 풀기"),
             symbol: "desktopcomputer", image: "routine_focus", ambience: .forest),
        make("work-after-meeting-5", .workBreak, 5,
             title: T(fr: "Après une réunion tendue", en: "After a tense meeting", de: "Nach einem angespannten Meeting", es: "Tras una reunión tensa", ja: "緊張した会議のあとで", ko: "긴장된 회의 후에"),
             subtitle: T(fr: "Évacuer la tension et choisir la suite", en: "Shake off the tension and choose what's next", de: "Spannung abschütteln und neu wählen", es: "Suelta la tensión y elige cómo seguir", ja: "緊張を振り払い、次を選ぶ", ko: "긴장을 털어내고 다음을 선택하기"),
             symbol: "person.2.wave.2.fill", image: "situation_submerge", ambience: .stream),
        make("work-screen-detox-6", .workBreak, 6,
             title: T(fr: "Détox d'écran", en: "Screen detox", de: "Bildschirm-Detox", es: "Desintoxicación de pantallas", ja: "スクリーン・デトックス", ko: "스크린 디톡스"),
             subtitle: T(fr: "Reposer les yeux et ralentir le flot de notifications", en: "Rest your eyes and slow the notification rush", de: "Augen ausruhen, Benachrichtigungsflut bremsen", es: "Descansa la vista y frena las notificaciones", ja: "目を休め、通知の嵐から離れる", ko: "눈을 쉬게 하고 알림의 홍수에서 벗어나기"),
             symbol: "eye.slash.fill", image: "meditation_07", ambience: .forest),
        make("work-end-of-day-8", .workBreak, 8,
             title: T(fr: "Fermer la journée", en: "Close the workday", de: "Den Arbeitstag abschließen", es: "Cierra la jornada", ja: "仕事を締めくくる", ko: "하루 업무 마무리"),
             subtitle: T(fr: "Ranger le travail pour retrouver ta soirée", en: "Put work away and get your evening back", de: "Arbeit ablegen, den Abend zurückgewinnen", es: "Guarda el trabajo y recupera tu tarde", ja: "仕事をしまって、夜の時間を取り戻す", ko: "일을 내려놓고 저녁을 되찾기"),
             symbol: "archivebox.fill", image: "meditation_04", ambience: .fire),

        // MARK: Sleep
        make("sleep-wind-down-10", .sleep, 10,
             title: T(fr: "Décompresser avant de dormir", en: "Unwind before sleep", de: "Abschalten vor dem Schlafen", es: "Desconecta antes de dormir", ja: "眠る前にほどく", ko: "잠들기 전 긴장 풀기"),
             subtitle: T(fr: "Laisser la journée derrière toi, souffle après souffle", en: "Leave the day behind, one breath at a time", de: "Den Tag hinter dir lassen, Atemzug für Atemzug", es: "Deja atrás el día, respiración a respiración", ja: "ひと呼吸ずつ、一日を後ろに", ko: "한 호흡씩 하루를 뒤로하기"),
             symbol: "bed.double.fill", image: "habit_sleep_night", ambience: .rain),
        make("sleep-body-heavy-15", .sleep, 15,
             title: T(fr: "Corps lourd, esprit calme", en: "Heavy body, quiet mind", de: "Schwerer Körper, ruhiger Geist", es: "Cuerpo pesado, mente en calma", ja: "重いからだ、静かな心", ko: "무거운 몸, 고요한 마음"),
             subtitle: T(fr: "Lourdeur et chaleur pour glisser vers le sommeil", en: "Heaviness and warmth to slip into sleep", de: "Schwere und Wärme, um in den Schlaf zu gleiten", es: "Pesadez y calor para deslizarte al sueño", ja: "重さと温かさで眠りへ", ko: "무거움과 따뜻함으로 잠에 스며들기"),
             symbol: "moon.zzz.fill", image: "situation_dormir", ambience: .ocean),
        make("sleep-racing-mind-12", .sleep, 12,
             title: T(fr: "Apaiser les pensées du soir", en: "Quiet a racing mind", de: "Kreisende Gedanken beruhigen", es: "Calma la mente acelerada", ja: "夜の考えごとを静める", ko: "밤의 생각 잠재우기"),
             subtitle: T(fr: "Quand le mental tourne en boucle au coucher", en: "When your thoughts keep spinning at bedtime", de: "Wenn die Gedanken abends kreisen", es: "Cuando los pensamientos no paran al acostarte", ja: "寝る前に考えが止まらないときに", ko: "잠자리에서 생각이 멈추지 않을 때"),
             symbol: "cloud.moon.fill", image: "meditation_08", ambience: .summerNight),
        make("sleep-back-to-sleep-8", .sleep, 8,
             title: T(fr: "Se rendormir la nuit", en: "Back to sleep", de: "Wieder einschlafen", es: "Volver a dormir", ja: "夜中にもう一度眠る", ko: "다시 잠들기"),
             subtitle: T(fr: "Réveillé·e en pleine nuit ? Sans pression, on repart", en: "Awake in the night? No pressure, let's drift back", de: "Nachts wach? Ohne Druck zurück in den Schlaf", es: "¿Despierto de noche? Sin presión, volvamos a dormir", ja: "夜中に目覚めても、焦らずに", ko: "한밤중에 깼다면, 부담 없이 다시"),
             symbol: "moon.fill", image: "meditation_01", ambience: .whitenoise),

        // MARK: Morning & energy
        make("morning-gentle-wake-5", .morning, 5,
             title: T(fr: "Réveil en douceur", en: "Gentle wake-up", de: "Sanft aufwachen", es: "Despertar suave", ja: "やさしい目覚め", ko: "부드러운 기상"),
             subtitle: T(fr: "Premiers souffles conscients, encore au lit", en: "First mindful breaths, still in bed", de: "Erste bewusste Atemzüge, noch im Bett", es: "Primeras respiraciones conscientes, aún en la cama", ja: "ベッドの中で、最初の意識的な呼吸", ko: "아직 침대에서, 첫 의식적인 호흡"),
             symbol: "sun.horizon.fill", image: "habit_sleep_morning", ambience: .morning),
        make("morning-intention-7", .morning, 7,
             title: T(fr: "Intention du jour", en: "Set your intention", de: "Tagesabsicht", es: "Intención del día", ja: "今日の意図", ko: "오늘의 의도"),
             subtitle: T(fr: "Choisir un mot pour guider ta journée", en: "Choose one word to guide your day", de: "Ein Wort wählen, das deinen Tag leitet", es: "Elige una palabra que guíe tu día", ja: "一日を導くひと言を選ぶ", ko: "하루를 이끌 한 단어 고르기"),
             symbol: "target", image: "situation_energie", ambience: .morning),
        make("morning-energy-4", .morning, 4,
             title: T(fr: "Énergie naturelle", en: "Natural energy", de: "Natürliche Energie", es: "Energía natural", ja: "自然なエネルギー", ko: "자연스러운 에너지"),
             subtitle: T(fr: "Réveiller le corps sans café", en: "Wake your body up without coffee", de: "Den Körper ohne Kaffee wecken", es: "Despierta el cuerpo sin café", ja: "コーヒーなしでからだを起こす", ko: "커피 없이 몸 깨우기"),
             symbol: "bolt.fill", image: "routine_energy", ambience: .forest),
        make("morning-gratitude-6", .morning, 6,
             title: T(fr: "Gratitude du matin", en: "Morning gratitude", de: "Morgendliche Dankbarkeit", es: "Gratitud matinal", ja: "朝の感謝", ko: "아침 감사"),
             subtitle: T(fr: "Trois mercis pour colorer la journée", en: "Three thank-yous to color your day", de: "Drei Dankesworte für deinen Tag", es: "Tres gracias para dar color al día", ja: "3つの「ありがとう」で一日を彩る", ko: "세 가지 감사로 하루 물들이기"),
             symbol: "sun.max.fill", image: "meditation_05", ambience: .stream),

        // MARK: Body & relaxation
        make("body-scan-10", .bodyRelax, 10,
             title: T(fr: "Scan corporel complet", en: "Full body scan", de: "Kompletter Bodyscan", es: "Escaneo corporal completo", ja: "全身ボディスキャン", ko: "전신 바디 스캔"),
             subtitle: T(fr: "Des orteils au sommet du crâne, sans jugement", en: "From toes to crown, without judgment", de: "Von den Zehen bis zum Scheitel, ohne Urteil", es: "De los pies a la cabeza, sin juzgar", ja: "つま先から頭頂まで、評価せずに", ko: "발끝에서 정수리까지, 판단 없이"),
             symbol: "figure.mind.and.body", image: "routine_relaxation", ambience: .rain),
        make("body-pmr-8", .bodyRelax, 8,
             title: T(fr: "Relâchement musculaire progressif", en: "Progressive muscle relaxation", de: "Progressive Muskelentspannung", es: "Relajación muscular progresiva", ja: "漸進的筋弛緩法", ko: "점진적 근육 이완"),
             subtitle: T(fr: "Contracter, puis relâcher, groupe après groupe", en: "Tense, then release, one muscle group at a time", de: "Anspannen und loslassen, Muskel für Muskel", es: "Tensa y suelta, grupo muscular a grupo muscular", ja: "力を入れて、ゆるめる。部位ごとに", ko: "긴장시키고, 풀어주기, 근육별로"),
             symbol: "hand.raised.fill", image: "meditation_02", ambience: .fire),
        make("body-shoulders-jaw-5", .bodyRelax, 5,
             title: T(fr: "Épaules et mâchoire", en: "Shoulders and jaw", de: "Schultern und Kiefer", es: "Hombros y mandíbula", ja: "肩とあご", ko: "어깨와 턱"),
             subtitle: T(fr: "Là où le stress se cache, on relâche", en: "Release where stress likes to hide", de: "Dort lösen, wo sich Stress versteckt", es: "Suelta donde se esconde el estrés", ja: "ストレスが隠れる場所をゆるめる", ko: "스트레스가 숨는 곳을 풀어주기"),
             symbol: "figure.cooldown", ambience: .ocean),
        make("body-yoga-nidra-15", .bodyRelax, 15,
             title: T(fr: "Yoga Nidra anti-stress", en: "Stress-relief yoga nidra", de: "Yoga Nidra gegen Stress", es: "Yoga nidra antiestrés", ja: "ストレス解消ヨガニドラ", ko: "스트레스 완화 요가 니드라"),
             subtitle: T(fr: "Le sommeil conscient pour un repos profond", en: "Conscious sleep for deep rest", de: "Bewusster Schlaf für tiefe Erholung", es: "Sueño consciente para un descanso profundo", ja: "意識ある眠りで深い休息を", ko: "깊은 휴식을 위한 의식적인 잠"),
             symbol: "moon.stars.fill", image: "routine_sleep", ambience: .summerNight),

        // MARK: Anxiety & emotions
        make("anxiety-grounding-54321-6", .anxiety, 6,
             title: T(fr: "Ancrage 5-4-3-2-1", en: "5-4-3-2-1 grounding", de: "5-4-3-2-1 Erdung", es: "Anclaje 5-4-3-2-1", ja: "5-4-3-2-1 グラウンディング", ko: "5-4-3-2-1 그라운딩"),
             subtitle: T(fr: "Revenir ici et maintenant avec tes cinq sens", en: "Come back to here and now with your five senses", de: "Mit fünf Sinnen ins Hier und Jetzt", es: "Vuelve al aquí y ahora con tus cinco sentidos", ja: "五感で「今ここ」に戻る", ko: "오감으로 지금 여기로 돌아오기"),
             symbol: "hand.point.up.left.fill", image: "situation_anxiete", ambience: .forest),
        make("anxiety-leaves-stream-8", .anxiety, 8,
             title: T(fr: "Feuilles sur la rivière", en: "Leaves on a stream", de: "Blätter auf dem Fluss", es: "Hojas en el río", ja: "川を流れる葉", ko: "시냇물 위의 나뭇잎"),
             subtitle: T(fr: "Regarder tes pensées passer sans t'y accrocher", en: "Watch your thoughts float by without holding on", de: "Gedanken vorbeiziehen lassen, ohne festzuhalten", es: "Mira pasar tus pensamientos sin aferrarte", ja: "考えにしがみつかず、流れていくのを眺める", ko: "생각에 매달리지 않고 흘러가게 바라보기"),
             symbol: "leaf.fill", ambience: .stream),
        make("anxiety-rain-method-7", .anxiety, 7,
             title: T(fr: "Accueillir l'émotion", en: "Meet your emotion", de: "Dem Gefühl begegnen", es: "Acoge tu emoción", ja: "感情を迎え入れる", ko: "감정을 맞이하기"),
             subtitle: T(fr: "La méthode RAIN pour traverser une émotion difficile", en: "The RAIN method to move through a hard feeling", de: "Die RAIN-Methode für schwierige Gefühle", es: "El método RAIN para atravesar una emoción difícil", ja: "RAIN法でつらい感情を乗り越える", ko: "RAIN 기법으로 힘든 감정 지나가기"),
             symbol: "cloud.rain.fill", ambience: .rain),
        make("anxiety-worry-release-9", .anxiety, 9,
             title: T(fr: "Déposer ses inquiétudes", en: "Set your worries down", de: "Sorgen ablegen", es: "Suelta tus preocupaciones", ja: "心配ごとを降ろす", ko: "걱정 내려놓기"),
             subtitle: T(fr: "Trier ce qui dépend de toi et lâcher le reste", en: "Sort what's in your control and let go of the rest", de: "Sortieren, was du beeinflussen kannst, Rest loslassen", es: "Separa lo que depende de ti y suelta el resto", ja: "自分にできることを選び、残りは手放す", ko: "내가 할 수 있는 것과 없는 것을 나누고 놓아주기"),
             symbol: "tray.and.arrow.down.fill", ambience: .fire),

        // MARK: Self-compassion
        make("compassion-kind-pause-5", .selfCompassion, 5,
             title: T(fr: "Pause bienveillante", en: "Self-compassion break", de: "Pause des Selbstmitgefühls", es: "Pausa de autocompasión", ja: "セルフ・コンパッションの休憩", ko: "자기 자비 휴식"),
             subtitle: T(fr: "Une main sur le cœur dans un moment difficile", en: "A hand on your heart in a hard moment", de: "Eine Hand aufs Herz in schweren Momenten", es: "Una mano en el corazón en un momento difícil", ja: "つらいとき、胸に手を当てて", ko: "힘든 순간, 가슴에 손을 얹고"),
             symbol: "hand.raised.square.fill", ambience: .ocean),
        make("compassion-loving-kindness-10", .selfCompassion, 10,
             title: T(fr: "Amour bienveillant", en: "Loving-kindness", de: "Liebende Güte", es: "Bondad amorosa", ja: "慈悲の瞑想", ko: "자애 명상"),
             subtitle: T(fr: "Envoyer de la douceur à toi et aux autres", en: "Send warmth to yourself and others", de: "Wärme an dich und andere senden", es: "Envía calidez a ti y a los demás", ja: "自分と他者にやさしさを送る", ko: "나와 타인에게 따뜻함 보내기"),
             symbol: "heart.circle.fill", image: "meditation_06", ambience: .morning),
        make("compassion-inner-critic-8", .selfCompassion, 8,
             title: T(fr: "Adoucir la critique intérieure", en: "Soften your inner critic", de: "Den inneren Kritiker besänftigen", es: "Suaviza a tu crítico interior", ja: "内なる批判の声をやわらげる", ko: "내면의 비판 목소리 누그러뜨리기"),
             subtitle: T(fr: "Te parler comme à un ami cher", en: "Speak to yourself like a dear friend", de: "Mit dir sprechen wie mit einem guten Freund", es: "Háblate como a un buen amigo", ja: "大切な友人に話すように自分に話す", ko: "소중한 친구에게 말하듯 나에게 말하기"),
             symbol: "bubble.left.and.text.bubble.right.fill", ambience: .fire),

        // MARK: Focus
        make("focus-single-point-6", .focus, 6,
             title: T(fr: "Point d'attention unique", en: "Single-point focus", de: "Ein Punkt der Aufmerksamkeit", es: "Atención en un solo punto", ja: "一点集中", ko: "한 점 집중"),
             subtitle: T(fr: "Compter les souffles pour entraîner ton attention", en: "Count your breaths to train your attention", de: "Atemzüge zählen, Aufmerksamkeit trainieren", es: "Cuenta respiraciones para entrenar tu atención", ja: "呼吸を数えて注意力を鍛える", ko: "호흡을 세며 주의력 훈련하기"),
             symbol: "scope", ambience: .whitenoise),
        make("focus-before-task-4", .focus, 4,
             title: T(fr: "Avant une tâche importante", en: "Before an important task", de: "Vor einer wichtigen Aufgabe", es: "Antes de una tarea importante", ja: "大事な作業の前に", ko: "중요한 일을 앞두고"),
             subtitle: T(fr: "Calmer le trac et lancer la première étape", en: "Calm the nerves and take the first step", de: "Nervosität beruhigen, ersten Schritt gehen", es: "Calma los nervios y da el primer paso", ja: "緊張を静め、最初の一歩を", ko: "긴장을 가라앉히고 첫걸음 내딛기"),
             symbol: "flag.checkered", ambience: nil),
        make("focus-mindful-breath-12", .focus, 12,
             title: T(fr: "Respiration en pleine conscience", en: "Mindful breathing", de: "Achtsames Atmen", es: "Respiración consciente", ja: "マインドフルな呼吸", ko: "마음챙김 호흡"),
             subtitle: T(fr: "La pratique classique pour un esprit clair", en: "The classic practice for a clear mind", de: "Die klassische Praxis für einen klaren Geist", es: "La práctica clásica para una mente clara", ja: "澄んだ心のための基本の瞑想", ko: "맑은 마음을 위한 기본 수련"),
             symbol: "wind", image: "meditation_05", colors: [Color(hex: "4F46E5"), Color(hex: "0EA5E9")], ambience: .stream)
    ]
}
