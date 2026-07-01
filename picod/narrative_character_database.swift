import Foundation

enum NarrativeCharacterKind: String, CaseIterable, Codable {
    case nightLamplighter
    case lostBackpacker
    case umbrellaWoman
    case toriiBetweenLight
    case doorKnocker
    case mirrorMiko

    case reverseWalker
    case paperEffigy
    case midnightFortuneKeeper
    case doppelPico
    case shadowlessVisitor
    case giantEdgeFigure
    case speakingEgg

    case treeFaceWatcher
    case hangingFigure
    case vanishingBird

    case mudling
    case mirrorFish
    case boneBird
    case growingWorm
    case headlessDeer
    case followingFog

    case duskPacker
    case duskLookingCat
    case starcountElder
    case midnightRegistrar
    case bedsideShape
    case dawnSweeper
}

enum NarrativeDialogueChannel: String, Codable {
    case greeting
    case encounter
    case farewell
}

struct NarrativeCharacterProfile: Codable, Hashable {
    let kind: NarrativeCharacterKind
    let titleZH: String
    let titleEN: String
    let storyFilePath: String
    let activeWindows: [String]
    let tags: [String]
}

enum NarrativeCharacterDatabase {
    static let profiles: [NarrativeCharacterKind: NarrativeCharacterProfile] = [
        .nightLamplighter: .init(kind: .nightLamplighter, titleZH: "点灯人", titleEN: "Night Lamplighter", storyFilePath: "storylines/night_lamplighter.md", activeWindows: ["dusk_or_night"], tags: ["first_batch", "ritual", "lantern"]),
        .lostBackpacker: .init(kind: .lostBackpacker, titleZH: "迷路背包客", titleEN: "Lost Backpacker", storyFilePath: "storylines/lost_backpacker.md", activeWindows: ["cycle2"], tags: ["first_batch", "outside", "edge"]),
        .umbrellaWoman: .init(kind: .umbrellaWoman, titleZH: "伞女", titleEN: "Umbrella Woman", storyFilePath: "storylines/umbrella_woman.md", activeWindows: ["rain_or_fog"], tags: ["first_batch", "weather", "watcher"]),
        .toriiBetweenLight: .init(kind: .toriiBetweenLight, titleZH: "鸟居之间的光", titleEN: "Light Between Torii", storyFilePath: "storylines/torii_between_light.md", activeWindows: ["torii_depth"], tags: ["first_batch", "torii", "cycle"]),
        .doorKnocker: .init(kind: .doorKnocker, titleZH: "敲门者", titleEN: "Door Knocker", storyFilePath: "storylines/door_knocker.md", activeWindows: ["day4_evening"], tags: ["first_batch", "repetition", "threshold"]),
        .mirrorMiko: .init(kind: .mirrorMiko, titleZH: "镜中巫女", titleEN: "Mirror Miko", storyFilePath: "storylines/mirror_miko.md", activeWindows: ["reflection"], tags: ["first_batch", "miko", "identity"]),

        .reverseWalker: .init(kind: .reverseWalker, titleZH: "倒着走的人", titleEN: "Reverse Walker", storyFilePath: "storylines/characters/reverse_walker.md", activeWindows: ["night", "fog"], tags: ["chinese_folklore", "anomaly"]),
        .paperEffigy: .init(kind: .paperEffigy, titleZH: "纸人", titleEN: "Paper Effigy", storyFilePath: "storylines/characters/paper_effigy.md", activeWindows: ["rain"], tags: ["chinese_folklore", "rain_only"]),
        .midnightFortuneKeeper: .init(kind: .midnightFortuneKeeper, titleZH: "午夜算命摊", titleEN: "Midnight Fortune Keeper", storyFilePath: "storylines/characters/midnight_fortune_keeper.md", activeWindows: ["night"], tags: ["chinese_folklore", "stall"]),
        .doppelPico: .init(kind: .doppelPico, titleZH: "替身", titleEN: "Doppel Pico", storyFilePath: "storylines/characters/doppel_pico.md", activeWindows: ["late_cycle"], tags: ["identity", "sync"]),
        .shadowlessVisitor: .init(kind: .shadowlessVisitor, titleZH: "没有影子的访客", titleEN: "Shadowless Visitor", storyFilePath: "storylines/characters/shadowless_visitor.md", activeWindows: ["day", "night"], tags: ["core_horror", "observer"]),
        .giantEdgeFigure: .init(kind: .giantEdgeFigure, titleZH: "走进来的东西", titleEN: "Edge Giant Figure", storyFilePath: "storylines/characters/edge_giant_figure.md", activeWindows: ["night", "cycle7"], tags: ["core_horror", "edge"]),
        .speakingEgg: .init(kind: .speakingEgg, titleZH: "会说话的蛋", titleEN: "Speaking Egg", storyFilePath: "storylines/characters/speaking_egg.md", activeWindows: ["post_hatch_wait"], tags: ["cycle", "voice"]),

        .treeFaceWatcher: .init(kind: .treeFaceWatcher, titleZH: "树里的脸", titleEN: "Face in Tree", storyFilePath: "storylines/characters/tree_face_watcher.md", activeWindows: ["fog", "low_participation"], tags: ["se_asia", "forest"]),
        .hangingFigure: .init(kind: .hangingFigure, titleZH: "倒挂的人形", titleEN: "Hanging Figure", storyFilePath: "storylines/characters/hanging_figure.md", activeWindows: ["night"], tags: ["se_asia", "tree"]),
        .vanishingBird: .init(kind: .vanishingBird, titleZH: "会跟着消失的鸟", titleEN: "Vanishing Bird", storyFilePath: "storylines/characters/vanishing_bird.md", activeWindows: ["day", "dusk"], tags: ["se_asia", "bird"]),

        .mudling: .init(kind: .mudling, titleZH: "泥人", titleEN: "Mudling", storyFilePath: "storylines/characters/mudling.md", activeWindows: ["rain", "low_participation"], tags: ["creature", "swamp"]),
        .mirrorFish: .init(kind: .mirrorFish, titleZH: "镜鱼", titleEN: "Mirror Fish", storyFilePath: "storylines/characters/mirror_fish.md", activeWindows: ["water"], tags: ["creature", "water"]),
        .boneBird: .init(kind: .boneBird, titleZH: "骨鸟", titleEN: "Bone Bird", storyFilePath: "storylines/characters/bone_bird.md", activeWindows: ["dusk"], tags: ["creature", "straight_flight"]),
        .growingWorm: .init(kind: .growingWorm, titleZH: "会生长的虫", titleEN: "Growing Worm", storyFilePath: "storylines/characters/growing_worm.md", activeWindows: ["idle_hours"], tags: ["creature", "persistent"]),
        .headlessDeer: .init(kind: .headlessDeer, titleZH: "无头鹿", titleEN: "Headless Deer", storyFilePath: "storylines/characters/headless_deer.md", activeWindows: ["forest", "night"], tags: ["creature", "deer"]),
        .followingFog: .init(kind: .followingFog, titleZH: "会跟随的雾团", titleEN: "Following Fog", storyFilePath: "storylines/characters/following_fog.md", activeWindows: ["fog", "night"], tags: ["creature", "friendly_or_not"]),

        .duskPacker: .init(kind: .duskPacker, titleZH: "收摊的人", titleEN: "Dusk Packer", storyFilePath: "storylines/characters/dusk_packer.md", activeWindows: ["dusk"], tags: ["dusk_only", "ritual"]),
        .duskLookingCat: .init(kind: .duskLookingCat, titleZH: "傍晚回头的猫", titleEN: "Dusk Looking Cat", storyFilePath: "storylines/characters/dusk_looking_cat.md", activeWindows: ["dusk"], tags: ["dusk_only", "cat"]),
        .starcountElder: .init(kind: .starcountElder, titleZH: "数星星的老人", titleEN: "Starcount Elder", storyFilePath: "storylines/characters/starcount_elder.md", activeWindows: ["night"], tags: ["night_only", "observer"]),
        .midnightRegistrar: .init(kind: .midnightRegistrar, titleZH: "夜间访客登记者", titleEN: "Midnight Registrar", storyFilePath: "storylines/characters/midnight_registrar.md", activeWindows: ["night"], tags: ["night_only", "threshold"]),
        .bedsideShape: .init(kind: .bedsideShape, titleZH: "睡着的巫女旁边的东西", titleEN: "Bedside Shape", storyFilePath: "storylines/characters/bedside_shape.md", activeWindows: ["deep_night"], tags: ["night_only", "miko"]),
        .dawnSweeper: .init(kind: .dawnSweeper, titleZH: "只在凌晨存在的人", titleEN: "Dawn Sweeper", storyFilePath: "storylines/characters/dawn_sweeper.md", activeWindows: ["dawn"], tags: ["dawn_only", "routine"])
    ]

    static func dialogue(for kind: NarrativeCharacterKind, languageCode: String, channel: NarrativeDialogueChannel, seed: Int = 0) -> String {
        let isZH = languageCode == "zh"
        let lines = linePool(for: kind, isZH: isZH, channel: channel)
        guard !lines.isEmpty else {
            return isZH ? "我今天在边缘听见了很轻的脚步。" : "I heard very light footsteps near the edge today."
        }
        let index = abs(seed) % lines.count
        return lines[index]
    }

    private static func linePool(for kind: NarrativeCharacterKind, isZH: Bool, channel: NarrativeDialogueChannel) -> [String] {
        switch kind {
        case .nightLamplighter:
            return isZH
                ? ["我只看见他的背影，然后下一盏灯亮了。", "今晚亮起的灯少了一盏，路像变长了。", "他没有回头，只把夜晚一点点点亮。"]
                : ["I only saw his back, then the next lamp turned warm.", "Tonight one fewer lamp came on, and the path felt longer.", "He did not turn around; he only lit the night in small pieces."]
        case .lostBackpacker:
            return isZH
                ? ["他展开地图，可地图上没有这里。", "他绕过同一个路口很多次，像每次都第一次来到。", "他的背包看起来来自外面，但外面没有入口。"]
                : ["He unfolded a map, but nothing on it matched this place.", "He circled the same crossing many times, as if arriving for the first time each time.", "His backpack looked like it came from outside, but there was no outside gate."]
        case .umbrellaWoman:
            return isZH
                ? ["雾里有人撑着伞站在边缘，我不确定她是不是一直在那里。", "伞没有移动，但我觉得被看见了。", "雨声很轻，她比雨声还安静。"]
                : ["In the mist, someone stood at the edge with an umbrella; I could not tell if she had always been there.", "The umbrella did not move, but I felt seen.", "The rain was quiet, and she was quieter than rain."]
        case .toriiBetweenLight:
            return isZH
                ? ["鸟居之间有一小块光停住了，像那里被谁占着。", "今晚鸟居之间的空气没有合上。", "那道光不像灯，更像时间露出的一点缝。"]
                : ["Between the torii, a small light held still, as if the space was occupied.", "Tonight the air between the gates did not close.", "The light felt less like a lamp than a seam in time."]
        case .doorKnocker:
            return isZH
                ? ["有人又敲门了。没有人开。", "敲门声来了三下，然后周围都安静了。", "我路过时那扇门像刚刚听完什么。"]
                : ["Someone knocked again. No one opened.", "The knocking came in threes, then everything around it went quiet.", "When I passed, the door seemed to have just heard something."]
        case .mirrorMiko:
            return isZH
                ? ["她的倒影慢了一拍。", "我看了两次，水面并不同意她的脚步。", "真实的巫女已经离开，倒影还停了一小会儿。"]
                : ["Her reflection moved a beat late.", "I looked twice; the water did not agree with her steps.", "The real miko had already left, but the reflection stayed a moment longer."]
        case .reverseWalker:
            return isZH
                ? ["他明明向前走，却一直看着来时的路。", "他倒着穿过路口，像在把时间往回推。", "我看了很久，还是分不清他是在离开还是回来。"]
                : ["He walked forward while facing where he had already been.", "He crossed the junction backward, as if pushing time in reverse.", "I watched for a while and still could not tell if he was leaving or returning."]
        case .paperEffigy:
            return isZH
                ? ["雨里站着一个很薄的白影，风吹过也不动。", "雨停后地上留下一个浅浅的人形水印。", "它像纸一样轻，却把周围压得很安静。"]
                : ["A very thin white figure stood in rain and did not move with wind.", "After rain stopped, a faint human-shaped wet mark stayed on the ground.", "It felt as light as paper, yet the air around it turned heavy and quiet."]
        case .midnightFortuneKeeper:
            return isZH
                ? ["午夜有个摊位亮着，他像是在等一个不会来的客人。", "我路过时他没有抬头，只把卦签排得更整齐。", "天亮前摊位就不见了，像从没来过。"]
                : ["A midnight stall stayed lit, as if waiting for a visitor who never arrives.", "When I passed, he did not look up and only aligned the fortune slips again.", "Before dawn, the stall was gone as if it had never appeared."]
        case .doppelPico:
            return isZH
                ? ["我看见另一个我，脚步和呼吸都和我同频。", "我们一起停下时，风像短暂卡住了一下。", "再眨眼时只剩我一个，像什么都没发生。"]
                : ["I saw another me, moving in the same rhythm of steps and breath.", "When we paused together, the wind seemed to hitch for a heartbeat.", "After one blink, only I remained, as if nothing had happened."]
        case .shadowlessVisitor:
            return isZH
                ? ["阳光下所有人都有影子，只有他没有。", "他走过路边时，地面像刻意避开了他。", "没有影子的访客总是比别人多停留几秒。"]
                : ["Under sunlight everyone had a shadow except that visitor.", "When the visitor passed, the ground seemed to avoid tracing a shape.", "The shadowless one always lingered a few seconds longer than others."]
        case .giantEdgeFigure:
            return isZH
                ? ["地图边缘站着一个很大的轮廓，夜里更清楚。", "它没有靠近，只是安静地站在边线外。", "我不确定那是不是在看我，还是在看整个世界。"]
                : ["A vast outline stood at the edge of the map, clearer at night.", "It did not approach; it only stayed beyond the boundary.", "I could not tell whether it was watching me or the whole world."]
        case .speakingEgg:
            return isZH
                ? ["我明明已经化成蛋，日记却继续写着。", "这些句子像我写的，却看见了我看不见的地方。", "蛋壳里很安静，但外面的事仍在被记录。"]
                : ["I had already become an egg, yet the diary kept writing.", "The voice sounded like mine but described places I could not see.", "Inside the shell it was quiet, while outside the world kept being recorded."]
        case .treeFaceWatcher:
            return isZH
                ? ["雾起时那棵树里会出现一张很浅的脸。", "它不动，只是看着路过的人。", "风越弱，那张脸越清楚。"]
                : ["When fog thickens, a faint face appears inside that tree.", "It does not move; it only watches those who pass.", "The weaker the wind, the clearer the face becomes."]
        case .hangingFigure:
            return isZH
                ? ["夜里树冠下有个倒挂的人形，轻轻晃着。", "它像被风托住，却从不落地。", "天亮前它总会先一步消失。"]
                : ["At night a hanging figure sways beneath the canopy.", "It seems held by wind and never touches ground.", "It always vanishes just before dawn arrives."]
        case .vanishingBird:
            return isZH
                ? ["那只鸟在我靠近时原地消失了。", "它没有飞走，只是像被擦掉一样不见。", "空气里只剩下一点没落完的羽音。"]
                : ["That bird vanished in place when I moved closer.", "It did not fly away; it disappeared as if erased.", "Only a small unfinished wing-sound remained in the air."]
        case .mudling:
            return isZH
                ? ["雨里泥人从地面慢慢鼓起来，然后开始爬行。", "它们不追谁，只在湿地边沿反复经过。", "雨停后它们又融回地里，像从没出现过。"]
                : ["In rain, mudlings swell up from ground and begin to crawl.", "They chase no one and keep tracing the wet edges.", "When rain ends, they melt back into earth as if never seen."]
        case .mirrorFish:
            return isZH
                ? ["水里的鱼总是用和周围相反的颜色游动。", "岸边越绿，它越偏红。", "我看着它，像看见水在反着做梦。"]
                : ["The fish in water always swam in colors opposite to its surroundings.", "The greener the shore, the redder it looked.", "Watching it felt like seeing water dream in reverse."]
        case .boneBird:
            return isZH
                ? ["黄昏有只骨白色的鸟直线穿过整张地图。", "它不绕树也不避屋顶，像路本来就在那里。", "一天只飞一次，像在确认某个坐标。"]
                : ["At dusk a bone-white bird crossed the whole map in a straight line.", "It avoided nothing, as if the route already existed.", "It flew once per day, like checking a coordinate."]
        case .growingWorm:
            return isZH
                ? ["角落里的小点每隔一段时间就长大一点。", "我不看它时，它长得更快。", "到第七天它会自己消失，像任务完成。"]
                : ["A tiny dot in the corner grew a little over time.", "It grew faster when I was not watching.", "By day seven it vanished on its own, as if its task ended."]
        case .headlessDeer:
            return isZH
                ? ["林里有一只鹿，身体完整却看不见头。", "它照常吃草和行走，像一切都很正常。", "我越想看清楚，它越像被雾抹平。"]
                : ["There was a deer in the forest with a body but no visible head.", "It grazed and walked as if nothing were wrong.", "The more I tried to focus, the more fog erased it."]
        case .followingFog:
            return isZH
                ? ["有团雾一直跟着我，保持着同样的距离。", "我停下它也停下，像在学我呼吸。", "我不知道它是朋友，还是某种耐心。"]
                : ["A fog cluster kept following me at a fixed distance.", "When I stopped, it stopped, as if copying my breath.", "I could not tell whether it was a friend or a patient watcher."]
        case .duskPacker:
            return isZH
                ? ["傍晚有人在收摊，可那里从来没有摊位。", "他折叠空气，打包不存在的货物。", "收完以后他照常离开，像日程从未出错。"]
                : ["At dusk someone packed up a stall that never existed.", "He folded air and bundled invisible goods.", "When done, he left on schedule as if nothing was unusual."]
        case .duskLookingCat:
            return isZH
                ? ["傍晚会有一只猫坐着，总朝我这边看。", "它不叫也不走，只在天黑前离开。", "每次位置不同，目光却都一样。"]
                : ["At dusk a cat sat quietly and kept facing my direction.", "It made no sound and left before full night.", "Its seat changed each day, but its gaze did not."]
        case .starcountElder:
            return isZH
                ? ["夜里有位老人坐着数星星，很久都不动。", "他头顶那一小片夜空星点更密。", "我离开时他还在数，像时间只剩数字。"]
                : ["At night an elder sat counting stars without moving for a long time.", "The sky above him carried more stars than nearby space.", "When I left, he was still counting, as if time had become numbers."]
        case .midnightRegistrar:
            return isZH
                ? ["夜里门前有人在等，像在做访客登记。", "门缝会亮一下，然后那个人就不见了。", "没有人解释谁被登记进去了。"]
                : ["At night someone waited at the door as if handling visitor records.", "A thin line of light appeared, then the figure was gone.", "No one explained who had been registered inside."]
        case .bedsideShape:
            return isZH
                ? ["巫女睡着时，她旁边会多一个很小的形状。", "它贴着坐着，天亮前自行退场。", "每次形状都不同，像在试着被看见。"]
                : ["When the miko slept, a tiny shape appeared beside her.", "It sat close and left before dawn.", "Its outline changed each time, as if trying different ways to be seen."]
        case .dawnSweeper:
            return isZH
                ? ["凌晨有个人只做一件事：扫地。", "白天谁都看不见他，像和世界错开了班次。", "我连着几天看见同样动作，像一段被守护的秩序。"]
                : ["At dawn there is someone who does one thing: sweeping.", "No one sees that figure in daytime, as if living on a shifted schedule.", "I saw the same routine for days, like a small order being protected."]
        }
    }
}
