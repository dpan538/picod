import Foundation

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
        save()
    }

    func story(for now: Date, timezoneIdentifier: String, languageCode: String) -> String? {
        let day = dayKey(for: now, timezoneIdentifier: timezoneIdentifier)
        let daily = records.filter { $0.dayKey == day }
        guard !daily.isEmpty else { return nil }

        var sequence: [PicoDiaryObject] = []
        sequence.reserveCapacity(daily.count)
        for item in daily where sequence.last != item.object {
            sequence.append(item.object)
        }

        let maxSlice = Array(sequence.suffix(10))
        guard !maxSlice.isEmpty else { return nil }

        let intro = languageCode == "zh"
            ? "今天，pico 在地图里缓慢走动，遇见了一些人和事。"
            : "Today, pico wandered slowly across the map and met a handful of people and moments."
        let outro = languageCode == "zh"
            ? "这些片段被串在一起，成为了 pico 的今天。"
            : "Threaded together, these fragments became pico's day."

        var paragraphs: [String] = [intro]
        for (index, obj) in maxSlice.enumerated() {
            paragraphs.append(storySentence(for: obj, indexSeed: index + day.hashValue, languageCode: languageCode))
        }
        paragraphs.append(outro)
        return paragraphs.joined(separator: "\n")
    }

    private func dayKey(for date: Date, timezoneIdentifier: String) -> String {
        var calendar = Calendar.current
        if let tz = TimeZone(identifier: timezoneIdentifier) {
            calendar.timeZone = tz
        }
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func storySentence(for object: PicoDiaryObject, indexSeed: Int, languageCode: String) -> String {
        let zh: [String]
        let en: [String]

        switch object {
        case .traveler:
            zh = ["边缘旅人沿着最外圈来回巡游，依旧没有跨入尘世。", "那位旅人再次在边框处折返，像在守着一条看不见的线。"]
            en = ["The border traveler looped the outer ring again, never stepping into the worldly center.", "The traveler turned back at the frame once more, guarding an unseen line."]
        case .spirit:
            zh = ["树林里的精灵停留很久，只在树旁轻轻盘旋。", "微光精灵围着同一簇树缓慢转圈，像在守护这片阴影。"]
            en = ["The forest spirit lingered for a long while, drifting gently near the same trees.", "A glimmering spirit circled one grove slowly, as if guarding the shade."]
        case .truckDriver:
            zh = ["下午的司机把食物从橙色货车搬到空地，一箱接一箱。", "司机在林缘短程往返，完成了今天的补给配送。"]
            en = ["In the afternoon, the driver moved food from the orange truck into the clearing, crate by crate.", "The driver made short loops by the forest edge to complete today's supply drop."]
        case .truck:
            zh = ["橙色货车停在林缘，临时补给点很快被布置起来。", "货车尾门打开后，空地边出现了整齐的食物箱。"]
            en = ["An orange truck stopped by the forest edge, and a temporary supply point took shape.", "With the rear gate open, neat food crates appeared along the clearing."]
        case .shrineMaiden:
            zh = ["巫女在神社前场巡视，北侧空气变得更安静。", "鸟居附近有巫女轻缓的步伐，节奏很克制。"]
            en = ["The shrine maiden tended the forecourt, and the north side grew quieter.", "Near the torii, her steps stayed light and restrained."]
        case .caretaker:
            zh = ["管家整理了住宅前的小路，花带也被重新修整。", "住宅区的细节被悄悄照看，秩序感慢慢回来了。"]
            en = ["The caretaker tidied the residential path and touched up the flower edge.", "Small details around the homes were quietly kept in order."]
        case .child:
            zh = ["右下角的孩子追着花瓣跑，让地图多了一点日常喧闹。", "孩子在路边蹲下又起身，像在寻找一个小秘密。"]
            en = ["The child in the southeast chased petals, adding a small pulse of daily life.", "The child crouched by the path and stood again, as if searching for a tiny secret."]
        case .fisher:
            zh = ["河边垂钓者几乎不说话，只是慢慢收放鱼线。", "松树下那位垂钓者保持着同样的安静节奏。"]
            en = ["The fisher by the stream spoke little, adjusting the line slowly.", "Under the pines, the fisher kept the same quiet rhythm."]
        case .bird:
            zh = ["一声鸟鸣把 pico 的脚步引向了更安静的草地。", "小鸟掠过树梢，只留下一段很短的声响。"]
            en = ["A bird call drew pico toward a quieter patch of grass.", "A small bird crossed the treetops, leaving only a brief sound behind."]
        case .deer:
            zh = ["林缘有鹿经过，停了一秒后又走进树影。", "鹿在树之间穿行，让这片区域更像真正的山林。"]
            en = ["A deer passed the forest edge, paused for a second, then slipped into the shade.", "The deer's movement between trees made the grove feel wilder."]
        case .bridge:
            zh = ["经过桥时，pico 在中央停了停，听下面的水声。", "桥把两侧路径重新接上，脚步也变得更有节奏。"]
            en = ["At the bridge, pico paused in the middle to listen to the water below.", "The bridge reconnected both paths and gave the walk a steadier rhythm."]
        case .shrine:
            zh = ["神社与鸟居之间很静，脚步自然慢了下来。", "北侧仪式区保持着克制，像在等待傍晚的灯。"]
            en = ["Between the shrine and torii, the air was still and the pace slowed naturally.", "The northern ceremonial area stayed restrained, as if waiting for evening lights."]
        case .lantern:
            zh = ["石灯亮起后，路口像被轻轻按下静音。", "灯光把几个节点串在一起，夜路更清晰了。"]
            en = ["Once the stone lanterns lit up, the corner felt gently muted.", "Lantern light stitched several nodes together and clarified the night path."]
        case .flowers:
            zh = ["花带边又落下新花瓣，路径像被轻轻点亮。", "风把花丛吹开一个小缺口，pico 在那里多停了一会儿。"]
            en = ["Fresh petals fell along the flower edge, softly brightening the route.", "Wind opened a small gap in the blossoms, and pico lingered there a little longer."]
        case .pond:
            zh = ["水边的停顿让节奏慢下来，像给今天留出一口气。", "池面的微波很轻，映着周围不断变化的光。"]
            en = ["A pause by the water slowed the pace and gave the day room to breathe.", "Gentle ripples held the changing light around the pond."]
        case .trees:
            zh = ["树影把外圈包起来，形成更安静的边界。", "林间的风让步伐慢了一点，路线更像散步。"]
            en = ["Tree shadows wrapped the outer ring into a quieter boundary.", "Wind in the grove slowed the pace and made the route feel more like a walk."]
        case .mushrooms:
            zh = ["蘑菇丛旁带着潮湿气味，pico 在那里显得很好奇。", "细碎的小蘑菇让这一角落更值得慢慢看。"]
            en = ["The mushroom patch smelled damp, and pico grew curious there.", "Tiny mushrooms made that corner worth a slower look."]
        case .sign:
            zh = ["木牌旁的短暂停留像一个安静转场。", "经过路牌后，pico 朝新的方向继续探索。"]
            en = ["A brief pause by the sign felt like a quiet transition.", "After passing the signpost, pico continued in a new direction."]
        case .unknown:
            zh = ["pico 又记录下一段细小而不易察觉的片段。"]
            en = ["pico recorded another small, almost imperceptible fragment."]
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
