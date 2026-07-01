import Foundation

struct PetResponseGenerator {
    private enum TimePhase {
        case morning
        case afternoon
        case dusk
        case night
    }

    static func response(for state: PetState, weather: WeatherCondition, languageCode: String) -> String {
        let phase = currentPhase()

        if let last = state.lastInteraction {
            switch last.type {
            case .sawAnimal:
                if let animal = last.sourceAnimal {
                    switch animal {
                    case .child:
                        if phase == .night {
                            return languageCode == "zh"
                                ? "夜里那个孩子提着小灯，脚步慢了很多。"
                                : "At night, the child moves slower with a small lantern."
                        }
                        return languageCode == "zh"
                            ? "右下角那个孩子今天还是很有精神。"
                            : "The child near the homes is full of energy today."
                    case .shrineMaiden:
                        return languageCode == "zh"
                            ? (phase == .dusk || phase == .night ? "巫女在灯下巡视，神社更安静了。" : "巫女让神社那边显得更安静了。")
                            : (phase == .dusk || phase == .night ? "The shrine maiden tending the grounds by lantern light feels especially calm." : "The shrine maiden makes the northern grounds feel calmer.")
                    case .caretaker:
                        return languageCode == "zh"
                            ? "管家把住宅前的路打理得很整齐。"
                            : "The caretaker keeps the residential path in order."
                    case .fisher:
                        return languageCode == "zh"
                            ? "河边的垂钓者几乎不动，但很安心。"
                            : "The fisher by the stream barely moves, and that feels peaceful."
                    default:
                        break
                    }
                }
                return languageCode == "zh"
                    ? "我刚刚注意到附近有小动物。"
                    : "I just noticed a little animal nearby."

            case .foundWater:
                return languageCode == "zh"
                    ? (phase == .morning ? "清晨的水边很轻，我喜欢那种安静。" : "水边很安静，我喜欢那里。")
                    : (phase == .morning ? "The morning water feels especially gentle." : "It feels calm near the pond.")

            case .restedByTree:
                return languageCode == "zh"
                    ? (phase == .night ? "夜里树影更深，我在那边休息了一会儿。" : "树边的风很轻，我休息了一会儿。")
                    : (phase == .night ? "The tree shadows are deeper at night. I rested there for a while." : "I rested by the trees for a while.")

            case .exploredMushroomPatch:
                return languageCode == "zh"
                    ? "蘑菇丛闻起来很有趣。"
                    : "The mushroom patch smells interesting."

            case .noticedObject:
                if let prop = last.sourceProp {
                    switch prop {
                    case .stoneLanternJp, .lantern:
                        return languageCode == "zh"
                            ? (phase == .dusk || phase == .night ? "石灯亮起来后，这里像变慢了一点。" : "白天的石灯也很好看，像在等傍晚。")
                            : (phase == .dusk || phase == .night ? "Once the stone lanterns light up, this corner feels slower." : "Even in daylight, the stone lanterns feel like they are waiting for dusk.")
                    case .shrineSmall, .torii, .pagoda:
                        return languageCode == "zh"
                            ? "神社那边的空气总是更安静。"
                            : "The shrine side always feels quieter."
                    case .japaneseBridge, .bridgeShort:
                        return languageCode == "zh"
                            ? "我经过桥的时候，总会往水里看一眼。"
                            : "Whenever I cross the bridge, I look at the water for a moment."
                    case .flowerBed, .pinkFlower, .yellowFlower:
                        return languageCode == "zh"
                            ? "花带边今天落了不少花瓣。"
                            : "There were more petals near the flower band today."
                    default:
                        break
                    }
                }
                return languageCode == "zh"
                    ? "我刚看了看附近的小东西。"
                    : "I was just checking something nearby."

            case .wandered, .tappedByUser:
                break
            }
        }

        if state.energy < 28 {
            return languageCode == "zh"
                ? "我今天走了很多地方，现在有点困。"
                : "I wandered a lot today. I am getting sleepy."
        }

        if weather == .sunny && state.mood == .happy {
            return languageCode == "zh"
                ? "今天天气很好，我很开心。"
                : "The weather is nice today. I am feeling happy."
        }

        if weather == .rainy || weather == .stormy {
            return languageCode == "zh"
                ? "今天有点潮湿，我在找舒服的地方。"
                : "It is a little damp today. I am finding a cozy spot."
        }

        if state.curiosity > state.comfort {
            return languageCode == "zh"
                ? "我还想再去看看前面的草地。"
                : "I still want to explore the meadow a little more."
        }

        switch phase {
        case .morning:
            return languageCode == "zh"
                ? "早上的风很轻，我想慢慢散步。"
                : "The morning air is light. I want to wander slowly."
        case .afternoon:
            return languageCode == "zh"
                ? "下午的光线很稳，我状态很好。"
                : "The afternoon light feels steady. I feel good."
        case .dusk:
            return languageCode == "zh"
                ? "天快暗了，我想去看看灯亮起来的地方。"
                : "It is getting dim. I want to visit the places where lights begin to glow."
        case .night:
            return languageCode == "zh"
                ? "夜里这里很安静，我会慢慢走。"
                : "It is quiet at night here. I will move slowly."
        }
    }

    private static func currentPhase() -> TimePhase {
        let hour = DevTestMode.hourOverride ?? Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .dusk
        default: return .night
        }
    }
}
