import Foundation
import Combine

struct PicoDiaryRecord: Codable, Hashable, Identifiable {
    let id: UUID
    let timestamp: Date
    let dayKey: String
    let object: PicoDiaryObject

    init(id: UUID = UUID(), timestamp: Date, dayKey: String, object: PicoDiaryObject) {
        self.id = id
        self.timestamp = timestamp
        self.dayKey = dayKey
        self.object = object
    }
}

enum PicoDiaryObject: String, Codable, Hashable {
    case traveler
    case spirit
    case truckDriver
    case truck
    case nightLamplighter
    case lostBackpacker
    case umbrellaWoman
    case toriiBetweenLight
    case doorKnocker
    case mirrorMiko
    case shrineMaiden
    case caretaker
    case child
    case fisher
    case bird
    case deer
    case bridge
    case shrine
    case lantern
    case flowers
    case pond
    case trees
    case mushrooms
    case sign
    case unknown

    static func from(event: PetEvent) -> PicoDiaryObject? {
        if let animal = event.sourceAnimal {
            switch animal {
            case .edgeTraveler: return .traveler
            case .forestSpirit: return .spirit
            case .truckDriver: return .truckDriver
            case .nightLamplighter: return .nightLamplighter
            case .lostBackpacker: return .lostBackpacker
            case .umbrellaWoman: return .umbrellaWoman
            case .toriiBetweenLight: return .toriiBetweenLight
            case .doorKnocker: return .doorKnocker
            case .mirrorMiko: return .mirrorMiko
            case .shrineMaiden: return .shrineMaiden
            case .caretaker: return .caretaker
            case .child: return .child
            case .fisher: return .fisher
            case .bird: return .bird
            case .deer: return .deer
            default: break
            }
        }

        if let prop = event.sourceProp {
            switch prop {
            case .orangeTruck: return .truck
            case .japaneseBridge, .bridgeShort: return .bridge
            case .shrineSmall, .torii, .pagoda: return .shrine
            case .stoneLanternJp, .lantern: return .lantern
            case .flowerBed, .pinkFlower, .yellowFlower: return .flowers
            case .mushroomPatch: return .mushrooms
            case .signpost: return .sign
            case .roundTree, .tallTree, .bigTree, .sacredEvergreen, .gardenPine, .tallPine, .dwarfPine,
                    .cherryTree, .weepingCherry, .cherryClump:
                return .trees
            default:
                break
            }
        }

        if let place = event.sourcePlace {
            switch place {
            case .pond, .shallowWater, .deepWater:
                return .pond
            case .forestEdge, .groveFloor, .mossGround:
                return .trees
            default:
                break
            }
        }

        switch event.type {
        case .foundWater:
            return .pond
        case .restedByTree:
            return .trees
        default:
            return nil
        }
    }
}

@MainActor
final class PicoDiaryDatabase: ObservableObject {
    @Published private(set) var records: [PicoDiaryRecord] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveTask: Task<Void, Never>?

    init() {
        self.fileURL = Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func recordInteraction(from event: PetEvent, timezoneIdentifier: String) {
        guard event.type != .wandered, event.type != .tappedByUser else { return }
        guard let object = PicoDiaryObject.from(event: event) else { return }

        let day = dayKey(for: event.timestamp, timezoneIdentifier: timezoneIdentifier)
        let candidate = PicoDiaryRecord(timestamp: event.timestamp, dayKey: day, object: object)

        if let last = records.last,
           last.object == candidate.object,
           abs(last.timestamp.timeIntervalSince(candidate.timestamp)) < 45 {
            return
        }

        records.append(candidate)
        if records.count > 3000 {
            records.removeFirst(records.count - 3000)
        }
        scheduleSave()
    }

    func story(for now: Date, timezoneIdentifier: String, languageCode: String, formId: Int) -> String? {
        let day = dayKey(for: now, timezoneIdentifier: timezoneIdentifier)
        let daily = records.filter { $0.dayKey == day }
        guard !daily.isEmpty else { return nil }
        let personality = MappingDatabase.personality(for: formId)

        // De-duplicate globally by object for a concise daily diary instead of a raw record list.
        var sequence: [PicoDiaryObject] = []
        var seen: Set<PicoDiaryObject> = []
        sequence.reserveCapacity(daily.count)
        for item in daily {
            if seen.insert(item.object).inserted {
                sequence.append(item.object)
            }
        }

        // Keep the diary compact: one intro + up to 5 scene beats + one outro.
        let maxSlice = Array(sequence.prefix(5))
        guard !maxSlice.isEmpty else { return nil }

        let intro = languageCode == "zh"
            ? "今天我在这片地图里慢慢走，风和光都比平时更容易被我注意到。"
            : "Today I moved slowly through the map, and for some reason I noticed the wind and light more than usual."
        let outro = languageCode == "zh"
            ? "这些相遇没有很喧闹，但拼在一起，就是我今天完整的一天。"
            : "None of these moments were loud, but together they became a full day for me."

        var paragraphs: [String] = [intro]
        for (index, obj) in maxSlice.enumerated() {
            paragraphs.append(
                storySentence(
                    for: obj,
                    personality: personality,
                    indexSeed: index + day.hashValue,
                    languageCode: languageCode
                )
            )
        }
        paragraphs.append(outro)

        let joined = paragraphs.joined(separator: "\n")
        // Hard cap to avoid overflowing beyond ~1.5 pages.
        let maxCharacters = languageCode == "zh" ? 340 : 560
        if joined.count <= maxCharacters { return joined }
        return String(joined.prefix(maxCharacters)) + (languageCode == "zh" ? "…" : "...")
    }

    func resetAll() {
        saveTask?.cancel()
        records = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func dayKey(for date: Date, timezoneIdentifier: String) -> String {
        var calendar = Calendar.current
        if let tz = TimeZone(identifier: timezoneIdentifier) {
            calendar.timeZone = tz
        }
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func storySentence(
        for object: PicoDiaryObject,
        personality: PicoPersonality,
        indexSeed: Int,
        languageCode: String
    ) -> String {
        let zh: [String]
        let en: [String]

        switch object {
        case .traveler:
            switch personality {
            case .natural:
                zh = ["我在外圈看到那位旅人时，先听见了脚步，再看到他折返。", "边缘旅人沿着外圈慢慢走，我跟了几步又退回草地。"]
                en = ["I heard the border traveler's steps before I saw him turn back at the frame.", "The edge traveler moved slowly along the outer ring; I followed for a few steps and drifted back."]
            case .ethereal:
                zh = ["边缘旅人走过时，我不确定他有没有看见我。", "我们在边界短暂重叠了一下，像两层影子擦肩而过。"]
                en = ["When the border traveler passed, I couldn't tell whether he could see me.", "We overlapped at the boundary for a moment, like two layers of shadow crossing."]
            case .artifact:
                zh = ["有人沿着边界经过，没有停下；我在原地等他走远。", "边缘旅人绕圈时，我像路边的标记一样安静地看着。"]
                en = ["Someone passed along the border without stopping; I waited until he moved on.", "As the edge traveler circled, I watched quietly like a marker by the path."]
            case .yokai:
                zh = ["那位守边的人知道外面有什么，我们彼此点了点头。", "边界上的脚步很轻，但每一步都像在提醒我某些旧规矩。"]
                en = ["The one guarding the edge seems to know what lies beyond; we acknowledged each other.", "The boundary footsteps were light, but each one felt like an old rule being repeated."]
            }
        case .spirit:
            switch personality {
            case .natural:
                zh = ["树间那团微光停得很久，像是在闻风里每一种气味。", "我靠近林间精灵时，它只挪了一点位置，还是守在那簇树旁。"]
                en = ["The soft glow lingered among the trees, as if it was scenting every change in the wind.", "When I moved toward the forest spirit, it shifted only slightly and stayed by the same grove."]
            case .ethereal:
                zh = ["林间精灵像一段会呼吸的雾，离我很近又很远。", "它绕树盘旋时，周围的安静像被折了两层。"]
                en = ["The forest spirit felt like breathing mist, near and far at the same time.", "As it looped around the trees, the silence felt doubled."]
            case .artifact:
                zh = ["那团光在树旁反复同一条路径，像在执行某个固定程序。", "我停在原地看它转了一圈又一圈，节奏很稳定。"]
                en = ["That glow repeated the same route by the trees, like it was following a fixed routine.", "I stayed still and watched it loop in a steady cadence."]
            case .yokai:
                zh = ["林间精灵今天没有回避我，像是默认我能听懂它的静默。", "它绕树的轨迹很旧，像早就存在于这片地形里。"]
                en = ["The forest spirit did not avoid me today, as if it accepted that I could read its silence.", "Its path around the trees felt ancient, as if it had always belonged to this terrain."]
            }
        case .truckDriver:
            switch personality {
            case .natural:
                zh = ["司机搬箱子时有很重的机油和纸箱味，我在树边闻了好一会儿。", "他走过碎石路的声音很稳，连我的步子也慢了下来。"]
                en = ["When the driver moved crates, the air filled with oil and cardboard, and I stayed by the trees smelling it.", "His steps on the gravel were steady, and my own pace slowed with that rhythm."]
            case .ethereal:
                zh = ["司机在空地来回时，我站在光边，不确定他有没有察觉到我。", "箱子一箱箱落地，声音很实，而我像在声音外面。"]
                en = ["As the driver crossed the clearing, I stayed at the edge of light, unsure if he sensed me.", "Each crate landed with a solid sound, while I felt just outside that weight."]
            case .artifact:
                zh = ["司机按固定顺序卸货，像完成一次标准补给流程。", "我在旁边观察每次停顿和转身，今天的节拍很整齐。"]
                en = ["The driver unloaded in a fixed sequence, like a standard supply procedure.", "I observed each pause and turn from the side; today's cadence was precise."]
            case .yokai:
                zh = ["司机又在林缘补货，像是每一轮都会重复的旧仪式。", "他的路线和停点几乎没变，这片地的规矩还在。"]
                en = ["The driver restocked the forest edge again, like an old rite repeated each cycle.", "His route and stopping points barely changed; the land's rules are still intact."]
            }
        case .truck:
            switch personality {
            case .natural:
                zh = ["货车一停下，空气就混进金属热味和新鲜食物味。", "尾门打开那一刻，空地像忽然有了今天的体温。"]
                en = ["As soon as the truck stopped, warm metal and fresh food scents mixed in the air.", "When the rear gate opened, the clearing suddenly felt warm with today's presence."]
            case .ethereal:
                zh = ["货车靠边时，周围都变得很实，我的轮廓却更薄了。", "它在那儿停着像一块锚点，而我只在边缘掠过。"]
                en = ["When the truck pulled in, everything around it felt solid while my outline thinned.", "It stood there like an anchor point, and I passed only along its edge."]
            case .artifact:
                zh = ["货车到位后，这一带的补给状态从空切换到可用。", "我看着尾门、车体和箱位对齐，系统感很完整。"]
                en = ["With the truck in position, this zone switched from empty supply state to active.", "I watched the rear gate, chassis, and crate positions align into a complete system."]
            case .yokai:
                zh = ["货车每次都在差不多的时辰停在林缘，像遵守旧约。", "它一出现，空地就知道今天该发生什么。"]
                en = ["The truck arrives at nearly the same hour each time, as if keeping an old pact.", "Once it appears, the clearing already knows what today's sequence will be."]
            }
        case .nightLamplighter:
            switch personality {
            case .natural:
                zh = ["点灯人走过后，空气里的冷意退了一点，我更愿意贴着亮路走。", "灯一盏盏亮起时，石路的声音也变得温和。"]
                en = ["After the lamplighter passed, the cold in the air eased and I stayed near the lit path.", "As each lantern came on, even the stone path sounded gentler."]
            case .ethereal:
                zh = ["他点亮一路灯火时，我像在光和影之间被短暂看见。", "我只看见他的背影和灯圈，像看见一段会重复的梦。"]
                en = ["As he lit the path, I felt briefly seen between light and shadow.", "I saw only his back and lantern halos, like watching a dream on repeat."]
            case .artifact:
                zh = ["点灯人的巡灯顺序稳定，夜间路径状态按段恢复。", "每盏灯亮起的间隔几乎一致，运行非常干净。"]
                en = ["The lamplighter's sequence is stable; the night path recovers segment by segment.", "The interval between each lantern activation was nearly constant and clean."]
            case .yokai:
                zh = ["夜里点灯人照旧走了一圈，像在沿古道重写边界。", "他不说话也不回头，但每盏灯都像记得他。"]
                en = ["The lamplighter made his usual night round, as if redrawing ancient boundaries.", "He neither spoke nor turned back, yet every lantern seemed to remember him."]
            }
        case .lostBackpacker:
            switch personality {
            case .natural:
                zh = ["背包客来回试路时，脚步里有点急味，我在旁边闻得出来。", "他总回到同一个路口，我也跟着绕了一小圈。"]
                en = ["As the backpacker tested routes, his hurried footsteps had a scent of tension I could feel.", "He kept returning to the same crossing, and I ended up circling with him once."]
            case .ethereal:
                zh = ["他摊开的地图对不上这里，我也像对不上他的方向感。", "他每次折返都更像在原地踏步，像被夜色轻轻推回去。"]
                en = ["His unfolded map did not match this place, and I felt equally unmatched with his sense of direction.", "Each return looked more like stepping in place, as if the dusk nudged him back."]
            case .artifact:
                zh = ["背包客重复了几条路径，结果都回到同一节点。", "他走过的每条路最后都回到同一个地方，我看了几圈确认不会变。"]
                en = ["The backpacker repeated several routes, all converging on the same node.", "Every route he tried ended at the same spot; I watched several loops and nothing changed."]
            case .yokai:
                zh = ["迷路的人又回到了旧路口，像被这片地的规矩轻轻按住。", "他找出口的方式很新，但困住他的方式很古老。"]
                en = ["The lost one returned to the old crossing again, as if held by the land's quiet rules.", "His way of searching was new, but the way he was trapped felt ancient."]
            }
        case .umbrellaWoman:
            switch personality {
            case .natural:
                zh = ["撑伞女人站在雾里不动，雨气和布料味在她身边停住了。", "我靠近时只听见伞边细小的滴水声。"]
                en = ["The umbrella woman stood still in mist, and rain scent with wet fabric lingered around her.", "When I moved closer, I heard only tiny drips along the umbrella rim."]
            case .ethereal:
                zh = ["她在雾里像一条被描出来的线，我不确定她是不是也在看我。", "我靠近时她没有动，像天气借了一个人的形状。"]
                en = ["In the mist she looked like a drawn line, and I couldn't tell if she was looking back.", "She did not move as I approached, like weather borrowing a human shape."]
            case .artifact:
                zh = ["她在中心视线方向保持静止，姿态持续稳定。", "我经过她身旁时，整段场景像被按下了静音。"]
                en = ["She maintained a fixed orientation toward the center with stable posture.", "As I passed her, the whole scene felt muted like a switch was pressed."]
            case .yokai:
                zh = ["雾里的撑伞人又出现了，她像在守一段只在这种天气开启的路。", "我经过她时没有说话，这种沉默已经重复很多次。"]
                en = ["The umbrella figure appeared in mist again, as if guarding a route that opens only in this weather.", "I passed her in silence; this kind of silence has repeated many times."]
            }
        case .toriiBetweenLight:
            switch personality {
            case .natural:
                zh = ["鸟居之间那团光出现时，周围的风像停了半拍。", "它淡下去后，空气里还留着一点发热的味道。"]
                en = ["When that light appeared between the torii, the wind paused for half a beat.", "After it faded, a faint warm trace remained in the air."]
            case .ethereal:
                zh = ["那团光停在两座鸟居中间，像一处短暂打开的缝。", "它不像人也不像灯，却像在确认我还在这里。"]
                en = ["The light held between the two torii like a briefly opened seam.", "It was neither person nor lantern, yet it felt like it confirmed I was still here."]
            case .artifact:
                zh = ["鸟居间出现短时光源，持续片刻后平稳消退。", "我记录了它的出现与消失，像一次异常但可重复的事件。"]
                en = ["A short-lived light source appeared between torii and decayed smoothly.", "I logged its emergence and fade like an anomalous but repeatable event."]
            case .yokai:
                zh = ["鸟居之间的光又来了，像在按固定时机点名。", "它停留的那几秒很短，却总让我想起旧祭的节拍。"]
                en = ["The light between torii returned again, like a roll call at a fixed hour.", "Its brief stay always reminds me of an older ritual rhythm."]
            }
        case .doorKnocker:
            switch personality {
            case .natural:
                zh = ["门外的敲击声很轻，但木头回响很清楚。", "停顿后他又敲了一次同样的节奏，我在旁边也不自觉屏住了气。"]
                en = ["The knocking outside was soft, but the wood's echo was clear.", "After a pause, the same rhythm came again, and I found myself holding my breath nearby."]
            case .ethereal:
                zh = ["那几下敲门声像从薄墙另一面传来，我不确定门里有没有人。", "敲门的人等了一会儿又重复一次，像在确认某种不存在的回应。"]
                en = ["The knocks felt like they came through a thin wall, and I couldn't tell if anyone was inside.", "The knocker waited and repeated the pattern, as if checking for an answer that wasn't there."]
            case .artifact:
                zh = ["敲门事件重复了同一节奏，间隔稳定。", "等了很久没有人来，一切又回到敲门之前的样子。"]
                en = ["The knocking event repeated an identical rhythm with stable interval.", "No one came for a long time, and everything returned to how it was before the knocking."]
            case .yokai:
                zh = ["门外的敲击又按旧节奏响起，像一段不肯结束的仪式。", "没有回应这件事本身，也像一种被默认的答案。"]
                en = ["The knocking resumed in the old rhythm again, like a rite that refuses to end.", "The lack of response itself felt like the expected answer."]
            }
        case .mirrorMiko:
            switch personality {
            case .natural:
                zh = ["水面的倒影慢了半拍，我先听见水纹再看见脚步。", "再看过去时，影子散开了，只剩下冷水气贴在石边。"]
                en = ["The reflection lagged by a beat; I heard the ripples before I read the steps.", "By the second look, the image had broken apart, leaving only cool water scent on stone."]
            case .ethereal:
                zh = ["巫女在水里的影子和真实不同步，像我自己的存在方式。", "我回头再看时，那道影已经像薄雾一样退回去。"]
                en = ["The miko's reflection moved out of sync with the real body, like my own way of existing.", "When I looked back, the image had withdrawn like thin mist."]
            case .artifact:
                zh = ["倒影慢了一拍，然后很快就平掉了，什么都没留下。", "我记下那一次不对齐，水面很快就当什么都没发生。"]
                en = ["The reflection fell behind by one beat, then smoothed out with nothing left.", "I noted the brief misalignment; the water moved on as if nothing had occurred."]
            case .yokai:
                zh = ["水中的巫女影像又慢了半拍，这种错位我见过很多次。", "它散去得很快，像把某段旧规矩悄悄收了回去。"]
                en = ["The miko image in water lagged again; I have seen this misalignment many times.", "It vanished quickly, as if an old rule had been quietly folded away."]
            }
        case .shrineMaiden:
            switch personality {
            case .natural:
                zh = ["巫女走得很慢，木屐和石地的声音把我的步子也压低了。", "她在鸟居旁停下时，风声都像被抚平了一点。"]
                en = ["The shrine maiden moved slowly, and the sound of sandals on stone lowered my pace too.", "When she paused by the torii, even the wind seemed smoothed out."]
            case .ethereal:
                zh = ["巫女经过时，我的轮廓也跟着安静下来。", "她停在鸟居前那几秒，我几乎分不清自己在光里还是影里。"]
                en = ["When the shrine maiden passed, even my outline settled into quiet.", "In those seconds she paused by the torii, I could barely tell whether I stood in light or shadow."]
            case .artifact:
                zh = ["巫女走过神社一圈，节奏很稳，那片区域安静如常。", "她在鸟居旁停了一下，确认了什么，然后继续走。"]
                en = ["The shrine maiden completed her round at a steady pace; that area stayed quietly in order.", "She paused by the torii for a moment, as if checking something, then moved on."]
            case .yokai:
                zh = ["巫女在鸟居前停下时，这片地像重新被命名了一次。", "她不急不慢地走过，连旧风都愿意让路。"]
                en = ["When the shrine maiden paused before the torii, the place felt renamed once again.", "She passed without hurry, and even the old wind seemed to make room."]
            }
        case .caretaker:
            switch personality {
            case .natural:
                zh = ["管家理顺小路后，地面的味道都变得干净了。", "我经过住宅前时步子更稳，像踩在被照看的土壤上。"]
                en = ["After the caretaker reset the path, even the ground smelled cleaner.", "My steps felt steadier near the homes, like walking on tended soil."]
            case .ethereal:
                zh = ["管家整理完门前后，连空气都像被抚平了一层。", "住宅区变得很整齐，我的轮廓也在那一带安静下来。"]
                en = ["After the caretaker arranged the doorfronts, even the air felt smoothed out.", "The residential side became so orderly that even my outline felt calmer there."]
            case .artifact:
                zh = ["管家把路径和门前重新排好，像完成了一次必要维护。", "我走过住宅区时，能感觉到每个节点都回到了正确位置。"]
                en = ["The caretaker reset the paths and doorfronts like a required maintenance pass.", "As I crossed the residential side, each node felt restored to the right place."]
            case .yokai:
                zh = ["管家今天把门前收得很干净，像是在替这片地守规矩。", "我路过住宅带时，觉得那些旧秩序还在正常运作。"]
                en = ["Today the caretaker kept every doorfront immaculate, as if preserving old rules for this place.", "Passing through the homes, I could feel the older order still operating."]
            }
        case .child:
            switch personality {
            case .natural:
                zh = ["右下角那个孩子又追着花瓣跑，笑声把草地都带热了一点。", "他忽蹲忽跳，我也跟着停了好几次。"]
                en = ["The child in the southeast chased petals again, and the laughter seemed to warm the grass.", "They kept crouching and springing up, and I kept stopping to watch."]
            case .ethereal:
                zh = ["孩子跑过我身边时，像从光里穿过去，没回头看我。", "他的笑声很近，却像隔着一层薄雾。"]
                en = ["When the child ran past me, it felt like moving through light; they never looked back.", "The laughter was close, yet sounded as if through a thin mist."]
            case .artifact:
                zh = ["孩子在住宅带重复小范围追逐，节奏轻快但稳定。", "我在路边看着他来回，像看一段不会出错的短循环。"]
                en = ["The child repeated a small pursuit loop in the residential zone, lively but consistent.", "I watched from the path edge like observing a short loop that never fails."]
            case .yokai:
                zh = ["那个孩子又在花带边跑动，像和这片地有旧交情。", "他踩过的路都很熟，像早就知道每个转角会发生什么。"]
                en = ["The child ran by the flower band again, as if carrying an old familiarity with this place.", "They moved with practiced turns, as if already knowing what each corner would bring."]
            }
        case .fisher:
            switch personality {
            case .natural:
                zh = ["河边钓者慢慢收线，水气和鱼腥味一起贴在风里。", "他几乎不说话，我也跟着把呼吸放慢。"]
                en = ["The fisher reeled in slowly, and water scent mixed with a faint fish smell in the wind.", "They barely spoke, and I slowed my breathing to match."]
            case .ethereal:
                zh = ["钓者在水边一动不动，我看着他像看一枚定住的影子。", "线入水的声音很轻，像在提醒我别太靠近现实。"]
                en = ["The fisher held still by the water, like a shadow fixed in place.", "The line touching water was a soft sound, reminding me not to lean too close to the real."]
            case .artifact:
                zh = ["钓者保持同一收线节奏，河边状态非常平稳。", "我在旁边计着他的停顿和动作，几乎没有偏差。"]
                en = ["The fisher maintained a consistent reeling cadence, and the riverside state stayed stable.", "I counted each pause and motion from nearby; the variance was minimal."]
            case .yokai:
                zh = ["松树下的钓者又在老位置守线，像在等一件很久以前的事。", "他收线的节拍很旧，听久了会让人忘记时间。"]
                en = ["The fisher under the pines held the old spot again, as if waiting for something from long ago.", "The rhythm of reeling felt ancient; listen long enough and time loosens."]
            }
        case .bird:
            switch personality {
            case .natural:
                zh = ["树上传来一声鸟鸣，我的耳朵先转过去，身子才跟上。", "它掠过树梢时只留下一小段风声。"]
                en = ["A bird call came from the trees; my ears turned first and my body followed.", "When it crossed the canopy, it left only a short trail of wind."]
            case .ethereal:
                zh = ["那声鸟鸣把我从发散里拉回来，像有人轻轻叫了我一声。", "鸟影一闪就没了，只剩空里还在振动。"]
                en = ["That bird call pulled me back from drifting, like being softly called by name.", "The bird's shape flashed and vanished, leaving vibration in empty air."]
            case .artifact:
                zh = ["鸟鸣在上方短促出现，随后环境噪声迅速归零。", "我记下了这段高频提示，持续时间很短。"]
                en = ["A brief bird signal appeared overhead, then ambient noise quickly returned to baseline.", "I logged the high-frequency cue; duration was short."]
            case .yokai:
                zh = ["树上的那一声像旧时的口令，来得很短却很准。", "鸟掠过时我抬头看了一眼，像在确认某种时辰。"]
                en = ["The call from the trees sounded like an old password—brief, precise.", "I looked up as the bird crossed, as if confirming a particular hour."]
            }
        case .deer:
            switch personality {
            case .natural:
                zh = ["林缘那只鹿停了一秒就进了树影，草叶被它擦得轻轻响。", "它经过时，整片边缘都有了更鲜活的山林味。"]
                en = ["The deer paused for a second at the forest edge, then slipped into shadow with leaves whispering against it.", "As it passed, the whole edge took on a fresher mountain scent."]
            case .ethereal:
                zh = ["鹿停住看向这边的一瞬间，我几乎以为它看见了我。", "它走进树影后，那里只剩下一块缓慢冷下去的安静。"]
                en = ["When the deer paused and looked this way, I almost thought it saw me.", "After it entered the shade, only a slowly cooling silence remained."]
            case .artifact:
                zh = ["鹿在边缘短暂停留后离开，路径非常干净。", "我记录了它的停点和离开方向，模式和昨天相近。"]
                en = ["The deer paused briefly at the edge and exited on a clean path.", "I logged the stop point and departure vector; the pattern matched yesterday."]
            case .yokai:
                zh = ["鹿在林缘停了一息，像在替山里确认一条旧线。", "它入林的动作很轻，却把周围都带回了古老的秩序。"]
                en = ["The deer paused at the forest edge for a breath, as if verifying an old line for the hills.", "Its entry into the grove was light, yet it restored an older order around it."]
            }
        case .bridge:
            switch personality {
            case .natural:
                zh = ["我走到桥中央停了一下，桥下水声刚好把心跳压慢。", "回头看时，两边的路像被木桥轻轻牵在一起。"]
                en = ["I paused at the bridge center, and the water below slowed my heartbeat.", "Looking back, both paths felt gently tied together by the wood span."]
            case .ethereal:
                zh = ["站在桥中央时，我像悬在两种安静之间。", "走过去再回头，桥把两侧的世界缝得很薄。"]
                en = ["At the center of the bridge, I felt suspended between two kinds of silence.", "After crossing, the bridge seemed to stitch both sides with a very thin seam."]
            case .artifact:
                zh = ["在桥中央短暂停驻后再继续，过桥过程顺畅。", "桥面把两侧路径稳定连接，通行状态良好。"]
                en = ["I paused briefly at the center, then resumed; crossing remained smooth.", "The bridge maintained a stable link between both paths; transit state was good."]
            case .yokai:
                zh = ["桥中央总像一条看不见的界线，我每次都会停一息。", "过桥回望时，那条旧路像又被悄悄接了回去。"]
                en = ["The bridge center always feels like an unseen boundary, and I pause there every time.", "Looking back after crossing, the old route seems quietly rejoined."]
            }
        case .shrine:
            switch personality {
            case .natural:
                zh = ["神社和鸟居之间总是很静，连风都绕着走。", "我每次经过那一带，步子都会自然放慢。"]
                en = ["Between the shrine and torii it is always still, even the wind seems to go around.", "Whenever I pass that zone, my steps slow on their own."]
            case .ethereal:
                zh = ["神社前的安静很深，像能把轮廓一点点抹平。", "我走过鸟居时，总有一瞬间分不清里外。"]
                en = ["The quiet before the shrine is deep, as if it smooths outlines away.", "When I pass the torii, there is always a moment I cannot tell inside from outside."]
            case .artifact:
                zh = ["神社区域长期保持低噪声和稳定节奏。", "我经过时确认了几个节点，一切都在正常位置。"]
                en = ["The shrine zone maintains low noise and steady cadence over time.", "As I passed, I checked several nodes; everything remained in expected position."]
            case .yokai:
                zh = ["神社前的空气像记得很久以前的脚步。", "我穿过鸟居时，总觉得这片地在轻声点名。"]
                en = ["The air before the shrine seems to remember footsteps from long ago.", "Crossing the torii, I always feel the place calling names under its breath."]
            }
        case .lantern:
            switch personality {
            case .natural:
                zh = ["石灯一亮，夜风就没那么冷了，我会贴着光走。", "灯光把路口照清楚后，脚下也安心很多。"]
                en = ["When the lanterns lit, the night wind felt less cold and I stayed close to the light.", "Once the corners were illuminated, my footing felt calmer."]
            case .ethereal:
                zh = ["灯亮起时，影子都被轻轻推开，我也更容易停留。", "那几圈灯光把夜色分层，让我有地方安静下来。"]
                en = ["When lanterns come on, shadows are gently pushed back and I can linger more easily.", "Those rings of light layer the night and give me somewhere to settle."]
            case .artifact:
                zh = ["灯光依次点亮后，夜间路径可读性明显提升。", "我沿着亮点巡过一圈，节奏很顺。"]
                en = ["Once lamps activated in sequence, nighttime path readability improved clearly.", "I ran one round along the lit nodes; cadence stayed smooth."]
            case .yokai:
                zh = ["石灯亮起时，这片地像被重新划出边界。", "我沿灯走了一圈，像沿着一段很旧的规矩。"]
                en = ["When the stone lanterns lit, the place felt re-bordered.", "I followed the lights in one loop, like tracing an old rule."]
            }
        case .flowers:
            switch personality {
            case .natural:
                zh = ["花带边新落的花瓣有很轻的甜味，我在那一段走得更慢。", "风吹开花丛一个小缺口时，我凑近闻了几秒。"]
                en = ["Fresh petals by the flower band carried a faint sweetness, and I slowed down there.", "When wind opened a small gap in the blossoms, I leaned in for a few breaths."]
            case .ethereal:
                zh = ["花瓣落下时像在空气里写了很短的一句话。", "我站在花带旁，看它们一片片从亮处飘进暗处。"]
                en = ["As petals fell, it felt like a very short sentence written in the air.", "I stood by the flowers watching each piece drift from light into shade."]
            case .artifact:
                zh = ["花带边的落瓣数量比平时多，路径边界更清晰。", "我在那段多停了一会儿，确认风向变化后再继续走。"]
                en = ["Petal density along the flower edge was higher than usual, sharpening the route boundary.", "I paused there to confirm the wind shift before moving on."]
            case .yokai:
                zh = ["花带今天落得很密，像在替这片地做一次无声告示。", "我经过时没有踩进花里，只沿着边缘慢慢走。"]
                en = ["Petals fell heavily today, like a silent notice posted by the land itself.", "I did not step into the flowers; I moved slowly along the edge."]
            }
        case .pond:
            switch personality {
            case .natural:
                zh = ["我在水边停了一会儿，潮气贴在脸上，今天像终于有了呼吸。", "池面的细波把光揉在一起，我看着看着就放松下来。"]
                en = ["I paused by the pond and felt damp air on my face; the day finally seemed to breathe.", "Small ripples folded light together, and I softened as I watched."]
            case .ethereal:
                zh = ["水面总能把我变得更轻，像把多余的轮廓都收走。", "我盯着波纹时，时间会慢下来一小截。"]
                en = ["Water always makes me lighter, as if it takes away extra outlines.", "When I follow the ripples, time slows by a small measure."]
            case .artifact:
                zh = ["水边停留后，整体节奏回到平稳区间。", "我看着波纹扩散和回收，像一组很可靠的周期。"]
                en = ["After pausing at the water, overall cadence returned to a stable band.", "I watched ripples expand and settle like a reliable cycle."]
            case .yokai:
                zh = ["池面今天很静，像一面不愿说话的旧镜。", "我在边上站了一会儿，听见很远的东西在回响。"]
                en = ["The pond was very still today, like an old mirror that refuses speech.", "I stood at the edge for a while and heard distant things echo back."]
            }
        case .trees:
            switch personality {
            case .natural:
                zh = ["树影把外圈包起来后，空气里全是树皮和潮土味。", "林间风不大，但足够让我每一步都慢下来。"]
                en = ["As tree shade wrapped the outer ring, the air filled with bark and damp soil.", "The grove wind was light, but enough to slow every step."]
            case .ethereal:
                zh = ["树影一层层压下来时，我像被放进更安静的壳里。", "我在林边走着走着，声音都变远了。"]
                en = ["As layers of tree shade settled, I felt enclosed in a quieter shell.", "Walking by the grove, every sound seemed to move farther away."]
            case .artifact:
                zh = ["树带保持了外圈的遮蔽和稳定边界。", "我沿林缘巡了一圈，通行与视线都很均衡。"]
                en = ["The tree band maintained cover and stable boundary along the outer ring.", "I ran one loop along the grove edge; visibility and passage stayed balanced."]
            case .yokai:
                zh = ["林缘今天很稳，像有谁提前把风和影排好了。", "我沿着树走时，总觉得这条外圈比看上去更深。"]
                en = ["The forest edge was steady today, as if someone arranged wind and shade in advance.", "As I walked along the trees, the outer ring felt deeper than it looked."]
            }
        case .mushrooms:
            switch personality {
            case .natural:
                zh = ["蘑菇丛边总有潮湿气味，我每次都会凑近闻。", "那一角落细节很多，慢慢看会让好奇心变强。"]
                en = ["There is always a damp scent by the mushrooms, and I lean in every time.", "That corner has many tiny details, and slow looking feeds my curiosity."]
            case .ethereal:
                zh = ["蘑菇丛像长在安静里，我靠近时连影子都放轻了。", "那一小片地方总让我觉得现实和梦贴得很近。"]
                en = ["The mushroom patch seems grown out of silence, and even my shadow softens near it.", "That little area always makes dream and reality feel close together."]
            case .artifact:
                zh = ["蘑菇区湿度持续偏高，但变化平稳。", "我在边上观察了一会儿，微小变化都很规律。"]
                en = ["Humidity in the mushroom zone stayed elevated but stable.", "I observed from the edge for a while; even small shifts were regular."]
            case .yokai:
                zh = ["蘑菇丛边像有一层旧气息，闻起来像被时间浸过。", "我在那儿停久一点，总会听见很细的回声。"]
                en = ["There is an old breath around the mushrooms, as if steeped in time.", "If I linger there, I always hear a very fine echo."]
            }
        case .sign:
            switch personality {
            case .natural:
                zh = ["木牌旁停一下总像换口气，我常会顺势换条路。", "每次经过路牌，我都觉得还能再往前走一点。"]
                en = ["Pausing by the sign always feels like taking a fresh breath, and I often switch routes after.", "Whenever I pass the signpost, I feel I can go a little farther."]
            case .ethereal:
                zh = ["路牌旁的停顿像一小段转场，我会在那儿重新对齐方向。", "木牌不说话，却总能把我从发散里拉回来。"]
                en = ["The pause by the sign feels like a small transition where I realign direction.", "The sign says nothing, yet it always draws me back from drifting."]
            case .artifact:
                zh = ["路牌节点提供了清晰分流，我在此调整了路径选择。", "短暂停留后再出发，路线读取更顺。"]
                en = ["The sign node offered a clear split, and I adjusted route choice there.", "After a short pause and restart, path reading became smoother."]
            case .yokai:
                zh = ["木牌立在这里很久了，像替道路记账。", "我每次经过都会看它一眼，像向旧路打个招呼。"]
                en = ["The sign has stood here for a long time, like a ledger for roads.", "I glance at it each time I pass, like greeting an old route."]
            }
        case .unknown:
            switch personality {
            case .natural:
                zh = ["我又记下一段很小却很真实的片段。", "它没有名字，但我记得它当时的气味和风。"]
                en = ["I recorded another small but very real fragment.", "It had no name, but I remember its scent and wind."]
            case .ethereal:
                zh = ["我又记下一段轻得几乎要散掉的片段。", "它很短，却在我身上停了很久。"]
                en = ["I recorded another fragment so light it almost dissolved.", "It was brief, yet stayed with me for a long time."]
            case .artifact:
                zh = ["我追加了一条短记录，留作今天的末尾标记。", "细节不多，但足够作为这段时间的注脚。"]
                en = ["I appended a short record as an end marker for today.", "Details were sparse, but enough for a clean annotation of this interval."]
            case .yokai:
                zh = ["我又记下一段无名片段，像从旧日里漂上来。", "它没有解释，但它出现过，这就够了。"]
                en = ["I recorded another unnamed fragment, as if it drifted up from older days.", "It offered no explanation, but it appeared—and that is enough."]
            }
        }

        let pool = languageCode == "zh" ? zh : en
        let idx = abs(indexSeed) % pool.count
        return pool[idx]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PicoDiaryRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, !Task.isCancelled else { return }
            self.save()
        }
    }

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("pico_diary_db.json")
    }
}
