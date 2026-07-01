import Foundation

struct PetResponseGenerator {
    private enum TimePhase {
        case morning
        case afternoon
        case dusk
        case night
    }

    static func response(
        for state: PetState,
        weather: WeatherCondition,
        languageCode: String
    ) -> String {
        response(for: state, weather: weather, personality: .natural, languageCode: languageCode)
    }

    static func response(
        for state: PetState,
        weather: WeatherCondition,
        personality: PicoPersonality,
        languageCode: String
    ) -> String {
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
                        switch personality {
                        case .natural:
                            return languageCode == "zh" ? "管家把住宅前的路理顺后，我走起来也更稳。" : "After the caretaker reset the path, my steps felt steadier too."
                        case .ethereal:
                            return languageCode == "zh" ? "管家整理过的门前很安静，连影子都被放平了。" : "After the caretaker's pass, even the shadows by the homes feel leveled."
                        case .artifact:
                            return languageCode == "zh" ? "管家完成了一次很干净的维护，路径状态良好。" : "The caretaker completed a clean maintenance pass; path state is stable."
                        case .yokai:
                            return languageCode == "zh" ? "管家守住了门前的秩序，这一带就会很稳。" : "The caretaker kept order at the doorfronts, and this district stayed steady."
                        }
                    case .fisher:
                        return languageCode == "zh"
                            ? "河边的垂钓者几乎不动，但很安心。"
                            : "The fisher by the stream barely moves, and that feels peaceful."
                    case .edgeTraveler:
                        switch personality {
                        case .natural:
                            return languageCode == "zh" ? "边缘旅人今天还在外圈巡游，我先听见了他的脚步。" : "The border traveler is circling the outer ring again; I heard the footsteps first."
                        case .ethereal:
                            return languageCode == "zh" ? "他沿着边界走过时，我不确定他有没有看见我。" : "As the border traveler passed the boundary, I couldn't tell whether he saw me."
                        case .artifact:
                            return languageCode == "zh" ? "有人沿着外圈经过，没有停留；我在原地记录了这一段。" : "Someone moved along the outer ring without stopping; I logged the pass quietly."
                        case .yokai:
                            return languageCode == "zh" ? "守边的人又出现了，边界今天依旧很清楚。" : "The edge keeper appeared again; the boundary is sharp tonight."
                        }
                    case .forestSpirit:
                        switch personality {
                        case .natural:
                            return languageCode == "zh" ? "树林里的精灵停了很久，像在闻风的变化。" : "The forest spirit lingered for a long time, as if reading shifts in the wind."
                        case .ethereal:
                            return languageCode == "zh" ? "那团微光在树影里转圈，像一段会呼吸的雾。" : "That glow loops in tree shade like breathing mist."
                        case .artifact:
                            return languageCode == "zh" ? "林间光点重复同一路径，节奏稳定得像程序。" : "The forest glow repeated the same path with a cadence that felt procedural."
                        case .yokai:
                            return languageCode == "zh" ? "林间精灵今天没有回避我，它像默认我能听懂它。" : "The forest spirit didn't avoid me today, as if it expected me to understand."
                        }
                    case .truckDriver:
                        return languageCode == "zh"
                            ? "下午的司机又把食物送到了林缘空地。"
                            : "The afternoon driver delivered food to the forest-edge clearing again."
                    case .nightLamplighter:
                        return languageCode == "zh"
                            ? "点灯人走过后，夜路会慢慢亮起来。"
                            : "After the lamplighter passes, the night path slowly brightens."
                    case .lostBackpacker:
                        return languageCode == "zh"
                            ? "那个背包客还是找不到出口。"
                            : "That backpacker still cannot find an exit."
                    case .umbrellaWoman:
                        return languageCode == "zh"
                            ? "雾里的撑伞女人今天也没有移动。"
                            : "The umbrella woman in the mist did not move today either."
                    case .toriiBetweenLight:
                        return languageCode == "zh"
                            ? "两座鸟居之间刚才有一团光。"
                            : "There was a pale light between the two torii just now."
                    case .doorKnocker:
                        return languageCode == "zh"
                            ? "我又听见了敲门声，但门还是没有开。"
                            : "I heard knocking again, but the door still did not open."
                    case .mirrorMiko:
                        return languageCode == "zh"
                            ? "水里的巫女倒影和脚步对不上。"
                            : "The miko reflection in the water moves out of step."
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
            switch personality {
            case .natural:
                return languageCode == "zh" ? "天很清，我闻得到草地在变暖。" : "The sky is clear and I can smell the meadow warming."
            case .ethereal:
                return languageCode == "zh" ? "晴天把边界照得很薄，我今天很轻。" : "Clear weather thins the edges of things; I feel lighter today."
            case .artifact:
                return languageCode == "zh" ? "天气稳定，今天的状态读数很好。" : "Conditions are stable; today's state readings are good."
            case .yokai:
                return languageCode == "zh" ? "晴朗的时候，很多旧痕迹会显出来。" : "In clear weather, old traces reveal themselves."
            }
        }

        if weather == .rainy || weather == .stormy {
            switch personality {
            case .natural:
                return languageCode == "zh" ? "今天很潮，我在找有泥土气味又能避雨的地方。" : "It's damp today; I'm looking for a sheltered place that still smells like earth."
            case .ethereal:
                return languageCode == "zh" ? "雨把声音都拉远了，我会贴着微光慢慢走。" : "Rain pulls every sound farther away; I'll move slowly along the light."
            case .artifact:
                return languageCode == "zh" ? "湿度偏高，但还能运行；先找干燥节点停留。" : "Humidity is high but still within operation; I'll pause near a dry node."
            case .yokai:
                return languageCode == "zh" ? "雨天会让旧路浮上来，我今天会沿着它们走。" : "Rain surfaces older routes; I'll follow those tonight."
            }
        }

        if state.curiosity > state.comfort {
            return languageCode == "zh"
                ? "我还想再去看看前面的草地。"
                : "I still want to explore the meadow a little more."
        }

        switch (phase, personality) {
        case (.morning, .natural):
            return languageCode == "zh" ? "早风很轻，我想沿着草地慢慢走。" : "The morning wind is soft; I want to drift along the meadow."
        case (.morning, .ethereal):
            return languageCode == "zh" ? "清晨的光很薄，我会贴着边界走一会儿。" : "Morning light is thin; I'll trace the boundary for a while."
        case (.morning, .artifact):
            return languageCode == "zh" ? "早间状态稳定，先巡一圈常用路径。" : "Morning state is stable; I'll run one pass on the usual route."
        case (.morning, .yokai):
            return languageCode == "zh" ? "清晨最适合听旧地方苏醒的声音。" : "Morning is best for hearing old places wake up."
        case (.afternoon, .natural):
            return languageCode == "zh" ? "下午光线很稳，我想多闻一会儿树边的风。" : "Afternoon light is steady; I want to linger by the trees."
        case (.afternoon, .ethereal):
            return languageCode == "zh" ? "午后的影子很短，我今天会更靠近人间一点。" : "Afternoon shadows are short; I can stay a little closer today."
        case (.afternoon, .artifact):
            return languageCode == "zh" ? "下午适合巡检，视野清楚、路径可读。" : "Afternoon is ideal for patrol: clear sightlines and readable paths."
        case (.afternoon, .yokai):
            return languageCode == "zh" ? "白天很亮，但有些细节只在慢走时才会显现。" : "Daylight is bright, but some details appear only at a slow pace."
        case (.dusk, .natural):
            return languageCode == "zh" ? "天在变暗，我会靠近有灯和花的地方。" : "It's dimming; I'll stay near lanterns and flowers."
        case (.dusk, .ethereal):
            return languageCode == "zh" ? "黄昏把轮廓变软了，这正适合我。" : "Dusk softens outlines; this is the right hour for me."
        case (.dusk, .artifact):
            return languageCode == "zh" ? "傍晚切换到低照模式，继续慢速巡航。" : "Switching to low-light mode at dusk; continuing slow patrol."
        case (.dusk, .yokai):
            return languageCode == "zh" ? "黄昏是门缝，我会从缝里看一眼今天的夜。" : "Dusk is a narrow gate; I'll peer through it into tonight."
        case (.night, .natural):
            return languageCode == "zh" ? "夜里有点凉，我会贴着亮路慢慢走。" : "Night air is cool; I'll stay near lit paths."
        case (.night, .ethereal):
            return languageCode == "zh" ? "夜里这里更像我的形状，我会慢一点。" : "At night this place feels more like my shape; I'll move slower."
        case (.night, .artifact):
            return languageCode == "zh" ? "夜间运行正常，维持低速与稳定节奏。" : "Night operation normal; maintaining low speed and stable cadence."
        case (.night, .yokai):
            return languageCode == "zh" ? "夜里会记得白天忘掉的事，我去边缘看看。" : "Night remembers what day forgets; I'll check the edges."
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
