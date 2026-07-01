import Foundation

struct VisionLabel: Codable, Hashable {
    let identifier: String
    let confidence: Float
}

struct ClusterScore: Codable, Hashable {
    let formId: Int
    let clusterName: String
    let primaryScore: Float
    let hitCount: Int
    let matchedLabels: [String]
    let priorityWeight: Int
    let nounScore: Float?
    let attributeScore: Float?
    let sceneScore: Float?
    let colorScore: Float?

    init(
        formId: Int,
        clusterName: String,
        primaryScore: Float,
        hitCount: Int,
        matchedLabels: [String],
        priorityWeight: Int,
        nounScore: Float? = nil,
        attributeScore: Float? = nil,
        sceneScore: Float? = nil,
        colorScore: Float? = nil
    ) {
        self.formId = formId
        self.clusterName = clusterName
        self.primaryScore = primaryScore
        self.hitCount = hitCount
        self.matchedLabels = matchedLabels
        self.priorityWeight = priorityWeight
        self.nounScore = nounScore
        self.attributeScore = attributeScore
        self.sceneScore = sceneScore
        self.colorScore = colorScore
    }
}

struct FormCluster: Codable, Hashable {
    let formId: Int
    let name: String
    let keywords: Set<String>
    let priorityWeight: Int
    let personality: PicoPersonality
}

enum PicoPersonality: String, Codable, Hashable {
    case natural
    case ethereal
    case artifact
    case yokai
}

struct SpecialRuleCategory: Codable, Hashable {
    let key: String
    let keywords: Set<String>
    let fallbackFormIds: [Int]
}

struct ColorRange: Codable, Hashable {
    let hueLow: Float
    let hueHigh: Float
    let satMin: Float
    let briMin: Float

    func matches(hue: Float, saturation: Float, brightness: Float) -> Bool {
        guard saturation >= satMin, brightness >= briMin else { return false }
        if hueLow <= hueHigh {
            return hue >= hueLow && hue <= hueHigh
        }
        return hue >= hueLow || hue <= hueHigh
    }
}

struct ColorBiasRule: Codable, Hashable {
    let range: ColorRange
    let bias: [Int: Float]
}

struct HSBColor: Codable, Hashable {
    let hue: Float
    let saturation: Float
    let brightness: Float
}

enum MappingDatabase {
    static let confidenceThreshold: Float = 0.4
    static let spookyFallbackRange: ClosedRange<Int> = 21...35
    static let naturalFallbackRange: ClosedRange<Int> = 1...20
    static let firstDayForbiddenFormIds: Set<Int> = [45, 66, 69, 70]
    static let safeHumanFallbackIds: [Int] = [1, 2, 3, 10, 11, 20]

    nonisolated(unsafe) static let synonyms: [String: String] = [
        "tabby cat": "tabby",
        "lightning bug": "firefly",
        "grey wolf": "wolf",
        "gray wolf": "wolf",
        "paper lantern": "lantern",
        "flying fox": "bat",
        "will o wisp": "ghost fire",
        "will-o-wisp": "ghost fire",
        "white cloth": "cloth",
        "double exposure": "overlap",
        "street light": "streetlight",
        "record player": "gramophone",
        "photo camera": "camera",
        "book page": "book",
        "joss paper": "offering paper",
        "bank note": "banknote"
    ]

    static let specialCategories: [SpecialRuleCategory] = [
        // Keep people photos in friendly companion space by default.
        .init(key: "human", keywords: ["person", "human", "face", "man", "woman", "boy", "girl", "body"], fallbackFormIds: safeHumanFallbackIds),
        .init(key: "food", keywords: ["food", "meal", "dish", "fruit", "berry", "mushroom"], fallbackFormIds: [54, 51, 81]),
        .init(key: "indoor", keywords: ["indoor", "interior", "room", "furniture", "ceiling", "floor"], fallbackFormIds: [57, 62, 96]),
        .init(key: "landscape", keywords: ["landscape", "sky", "mountain", "field", "horizon", "cloud"], fallbackFormIds: [55, 48]),
        .init(key: "text", keywords: ["text", "book", "letter", "document", "newspaper", "writing"], fallbackFormIds: [58, 23]),
        .init(key: "night", keywords: ["night", "dark", "moonlight", "nighttime"], fallbackFormIds: [30, 41, 117])
    ]

    static let clusters: [FormCluster] = makeClusters()

    static let attributeWeightTable: [String: [Int: Float]] = [
        "red": [71: 0.25, 77: 0.22, 39: 0.18, 64: 0.15, 41: 0.12],
        "green": [47: 0.25, 50: 0.22, 46: 0.20, 26: 0.15, 73: 0.18],
        "blue": [48: 0.22, 116: 0.20, 117: 0.18, 118: 0.22, 119: 0.18],
        "white": [23: 0.22, 25: 0.25, 49: 0.22, 55: 0.20, 85: 0.15],
        "black": [24: 0.05, 74: 0.25, 32: 0.22, 84: 0.20, 35: 0.15],
        "grey": [76: 0.22, 79: 0.20, 90: 0.22, 34: 0.18, 75: 0.15],
        "fluffy": [1: 0.22, 2: 0.20, 9: 0.22, 55: 0.18, 91: 0.20],
        "smooth": [62: 0.20, 75: 0.18, 83: 0.22, 73: 0.18],
        "rough": [90: 0.22, 34: 0.20, 89: 0.22, 76: 0.18, 79: 0.20],
        "shiny": [75: 0.25, 71: 0.22, 73: 0.20, 96: 0.18, 100: 0.18],
        "wet": [48: 0.22, 26: 0.20, 47: 0.15, 118: 0.22, 13: 0.18],
        "soft": [55: 0.20, 91: 0.22, 2: 0.18, 83: 0.22, 93: 0.18],
        "round": [5: 0.18, 55: 0.22, 83: 0.22, 49: 0.20, 96: 0.18],
        "long": [8: 0.25, 53: 0.22, 98: 0.22, 108: 0.20],
        "wooden": [33: 0.22, 53: 0.25, 61: 0.22, 97: 0.20, 76: 0.18],
        "metal": [75: 0.25, 96: 0.22, 100: 0.22, 57: 0.20, 113: 0.18],
        "glass": [66: 0.25, 80: 0.22, 107: 0.20, 68: 0.18],
        "stone": [76: 0.28, 79: 0.25, 90: 0.22, 34: 0.20, 7: 0.18],
        "fabric": [91: 0.22, 93: 0.25, 95: 0.20, 94: 0.22, 92: 0.18],
        "paper": [23: 0.28, 36: 0.22, 104: 0.22, 58: 0.20, 42: 0.18],
        "ceramic": [62: 0.28, 82: 0.20, 81: 0.18, 85: 0.15],
        "glowing": [17: 0.25, 41: 0.22, 30: 0.22, 56: 0.20, 116: 0.18],
        "floating": [21: 0.22, 55: 0.20, 41: 0.22, 17: 0.18, 120: 0.15],
        "broken": [67: 0.35, 35: 0.20, 79: 0.18, 62: 0.15],
        "frozen": [86: 0.30, 25: 0.25, 49: 0.22, 73: 0.15]
    ]

    static let sceneFilterTable: [String: [Int: Float]] = [
        "outdoor": [47: 0.20, 50: 0.18, 46: 0.18, 77: 0.20, 76: 0.18, 56: -0.20, 80: -0.20],
        "indoor": [56: 0.20, 57: 0.18, 62: 0.18, 80: 0.22, 64: 0.18, 33: -0.18, 88: -0.20],
        "water": [4: 0.25, 13: 0.22, 16: 0.22, 19: 0.20, 26: 0.22, 48: 0.22, 118: 0.25],
        "forest": [47: 0.25, 33: 0.22, 46: 0.22, 50: 0.20, 10: 0.18, 11: 0.18, 80: -0.18],
        "mountain": [27: 0.22, 90: 0.22, 9: 0.18, 11: 0.18, 86: 0.20, 4: -0.18],
        "sky": [55: 0.25, 3: 0.22, 116: 0.22, 117: 0.20, 119: 0.18, 89: -0.20],
        "garden": [76: 0.25, 52: 0.20, 46: 0.18, 47: 0.18, 54: 0.18, 32: -0.20],
        "shrine": [77: 0.28, 76: 0.25, 28: 0.22, 27: 0.20, 30: 0.18],
        "night": [21: 0.22, 24: 0.02, 30: 0.25, 41: 0.22, 116: 0.22, 117: 0.25, 3: -0.18],
        "foggy": [21: 0.25, 87: 0.30, 24: 0.22, 25: 0.20, 68: 0.18],
        "rainy": [48: 0.28, 26: 0.20, 87: 0.22, 118: 0.20, 23: 0.18],
        "snowy": [49: 0.28, 25: 0.25, 86: 0.25, 55: 0.18]
    ]

    static let colorBiasTable: [ColorBiasRule] = [
        .init(range: .init(hueLow: 345, hueHigh: 15, satMin: 0.5, briMin: 0.3), bias: [71: 0.28, 77: 0.25, 39: 0.20, 64: 0.18, 41: 0.15]),
        .init(range: .init(hueLow: 15, hueHigh: 45, satMin: 0.4, briMin: 0.3), bias: [72: 0.28, 88: 0.20, 54: 0.18, 64: 0.15]),
        .init(range: .init(hueLow: 45, hueHigh: 70, satMin: 0.3, briMin: 0.4), bias: [17: 0.25, 72: 0.22, 96: 0.20, 41: 0.18]),
        .init(range: .init(hueLow: 70, hueHigh: 100, satMin: 0.3, briMin: 0.3), bias: [47: 0.25, 50: 0.22, 54: 0.20, 51: 0.18]),
        .init(range: .init(hueLow: 100, hueHigh: 150, satMin: 0.3, briMin: 0.2), bias: [47: 0.28, 50: 0.25, 46: 0.22, 26: 0.20, 53: 0.18, 73: 0.20]),
        .init(range: .init(hueLow: 150, hueHigh: 195, satMin: 0.3, briMin: 0.3), bias: [73: 0.25, 118: 0.22, 26: 0.20, 48: 0.18]),
        .init(range: .init(hueLow: 195, hueHigh: 250, satMin: 0.3, briMin: 0.2), bias: [48: 0.25, 116: 0.22, 117: 0.22, 118: 0.20, 119: 0.18]),
        .init(range: .init(hueLow: 250, hueHigh: 290, satMin: 0.3, briMin: 0.2), bias: [119: 0.25, 116: 0.22, 37: 0.20, 29: 0.18]),
        .init(range: .init(hueLow: 290, hueHigh: 330, satMin: 0.3, briMin: 0.2), bias: [37: 0.25, 119: 0.22, 52: 0.18, 29: 0.18]),
        .init(range: .init(hueLow: 330, hueHigh: 345, satMin: 0.3, briMin: 0.3), bias: [52: 0.28, 2: 0.20, 91: 0.18, 95: 0.18]),
        .init(range: .init(hueLow: 0, hueHigh: 360, satMin: 0.0, briMin: 0.8), bias: [23: 0.25, 25: 0.22, 49: 0.20, 55: 0.22, 21: 0.18]),
        .init(range: .init(hueLow: 0, hueHigh: 360, satMin: 0.0, briMin: 0.0), bias: [74: 0.25, 32: 0.22, 84: 0.20, 35: 0.18])
    ]

    nonisolated static func personality(for formId: Int) -> PicoPersonality {
        // Explicit overrides first for IDs that also appear in broader ranges.
        switch formId {
        case 71, 108, 109, 112, 115, 118:
            return .yokai
        case 49, 55, 114:
            return .ethereal
        default:
            break
        }

        if (1...20).contains(formId) || (46...55).contains(formId) || (71...90).contains(formId) {
            return .natural
        }
        if (21...25).contains(formId) || formId == 29 || (66...70).contains(formId) {
            return .ethereal
        }
        if (56...65).contains(formId) || [76, 78, 81, 91, 111, 113, 116, 117, 119, 120].contains(formId) || (96...107).contains(formId) {
            return .artifact
        }
        if (26...28).contains(formId) || (30...45).contains(formId) {
            return .yokai
        }
        return .natural
    }

    nonisolated static func normalize(_ raw: String) -> String {
        let lower = raw.lowercased()
        let separated = lower
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let scalar = separated.unicodeScalars.filter { CharacterSet.alphanumerics.union(.whitespaces).contains($0) }
        let compact = String(String.UnicodeScalarView(scalar))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return synonyms[compact] ?? compact
    }

    nonisolated private static func makeClusters() -> [FormCluster] {
        [
            c(1, "狸猫", 90, ["cat", "kitten", "tabby", "persian cat", "maine coon", "raccoon", "tanuki", "red panda"]),
            c(2, "兔", 80, ["rabbit", "bunny", "hare", "cottontail"]),
            c(3, "鸟", 70, ["bird", "sparrow", "swallow", "pigeon", "crow", "parrot", "canary", "robin", "finch"]),
            c(4, "鱼", 68, ["fish", "goldfish", "koi", "carp", "salmon", "trout", "clownfish", "angelfish"]),
            c(5, "青蛙", 65, ["frog", "toad", "salamander", "newt", "amphibian"]),
            c(6, "猫头鹰", 72, ["owl", "eagle", "hawk", "falcon", "vulture", "raptor"]),
            c(7, "乌龟", 60, ["turtle", "tortoise", "snail", "shell", "terrapin"]),
            c(8, "蛇", 75, ["snake", "serpent", "eel", "worm", "centipede", "lizard", "gecko"]),
            c(9, "熊", 66, ["bear", "panda", "koala", "polar bear", "grizzly", "pig", "hippo", "boar"]),
            c(10, "狐", 74, ["fox", "wolf", "coyote", "jackal", "fennec"]),
            c(11, "鹿", 69, ["deer", "reindeer", "elk", "moose", "antelope", "stag", "fawn", "caribou"]),
            c(12, "蝙蝠", 62, ["bat", "pterodactyl"]),
            c(13, "水獭", 58, ["otter", "beaver", "mink", "muskrat", "platypus", "seal", "sea lion"]),
            c(14, "刺猬", 57, ["hedgehog", "porcupine", "echidna", "sea urchin", "pinecone", "chestnut"]),
            c(15, "螃蟹", 56, ["crab", "lobster", "shrimp", "crayfish", "scorpion", "spider"]),
            c(16, "章鱼", 61, ["octopus", "squid", "jellyfish", "nautilus", "starfish", "sea anemone"]),
            c(17, "萤火虫", 59, ["firefly", "glowworm", "fairy light", "sparkle", "bioluminescent", "glow"]),
            c(18, "蚕", 52, ["caterpillar", "silkworm", "larva", "grub", "cocoon", "chrysalis"]),
            c(19, "鲸", 55, ["whale", "dolphin", "shark", "manatee", "dugong", "manta ray", "giant squid"]),
            c(20, "犬", 64, ["dog", "puppy", "labrador", "golden retriever", "shiba", "corgi", "husky", "dalmatian"]),
            c(21, "鬼魂", 85, ["smoke", "fog", "mist", "veil", "cloth", "curtain", "ghost", "translucent"]),
            c(22, "面具", 84, ["mask", "theatre mask", "carnival mask", "face paint", "helmet"]),
            c(23, "纸人", 83, ["paper", "origami", "newspaper", "tissue", "scroll", "parchment"]),
            c(24, "影", 83, ["shadow", "silhouette", "eclipse"]),
            c(25, "雪女", 81, ["snow", "ice", "frost", "icicle", "blizzard", "white hair", "pale skin"]),
            c(26, "河童", 80, ["pond", "swamp", "lily pad", "lotus", "wetland", "marsh", "algae", "river bank"]),
            c(27, "天狗", 79, ["mountain", "cliff", "red leaves", "autumn", "tengu", "crow feather", "fan"]),
            c(28, "座敷童", 78, ["kimono", "yukata", "traditional clothing", "child room", "tatami", "doll"]),
            c(29, "轰隆", 78, ["thunder", "lightning", "storm cloud", "static", "electric", "plasma", "aurora"]),
            c(30, "提灯小僧", 82, ["lantern", "candle", "torch", "oil lamp", "festival light"]),
            c(31, "骨女", 76, ["bone", "skeleton", "fossil", "ivory", "coral", "dried wood", "bleached"]),
            c(32, "海坊主", 76, ["deep sea", "ocean", "dark water", "abyss", "kraken", "tide"]),
            c(33, "木灵", 77, ["tree hollow", "old tree", "forest", "ancient wood", "bark", "trunk", "gnarled"]),
            c(34, "泥田坊", 75, ["mud", "clay", "dirt", "soil", "one eye", "crack", "earth", "silt"]),
            c(35, "狂骨", 75, ["ruins", "broken", "torn fabric", "decay", "abandoned", "weathered", "old kimono"]),
            c(36, "僵尸", 74, ["talisman", "paper charm", "incense", "ritual", "yellow paper", "stamp", "seal"]),
            c(37, "狐仙", 74, ["multiple tails", "flowing fabric", "ethereal", "shrine", "nine tails", "spiritual"]),
            c(38, "山魈", 72, ["red face", "body hair", "primate", "ape", "monkey", "mountain creature"]),
            c(39, "夜叉", 72, ["weapon", "sword", "spear", "anger", "warrior", "blue", "fierce", "battle"]),
            c(40, "飞头", 71, ["floating head", "severed", "neck", "viscera", "organ", "entrails"]),
            c(41, "鬼火", 78, ["blue flame", "green fire", "ghost fire", "swamp gas", "phosphorescence"]),
            c(42, "纸钱鬼", 70, ["money", "coin", "banknote", "offering", "altar", "incense smoke", "offering paper"]),
            c(43, "蛊虫", 69, ["insect swarm", "ants", "flies", "beetles", "cluster", "hive", "colony", "infestation"]),
            c(44, "倒吊人", 71, ["upside down", "hanging", "rope", "chandelier", "stalactite", "inverted", "dangling"]),
            c(45, "影鬼", 74, ["mirror", "reflection", "duplicate", "copy", "symmetry", "doppelganger"]),
            c(46, "苔藓人", 66, ["moss", "lichen", "wet stone", "damp", "green rock", "forest floor", "undergrowth"]),
            c(47, "树灵", 67, ["tree", "oak", "maple", "zelkova", "willow", "tree top", "canopy", "grove"]),
            c(48, "雨人", 68, ["rain", "drizzle", "puddle", "stream", "waterfall", "dew", "wet surface", "droplet"]),
            c(49, "雪人", 63, ["snowman", "snowball", "blizzard", "snowflake", "white mound", "powder snow"]),
            c(50, "藤蔓人", 66, ["vine", "ivy", "creeper", "tendril", "climbing plant", "overgrown", "entangled"]),
            c(51, "蘑菇", 64, ["mushroom", "fungus", "toadstool", "spore", "bracket fungus", "truffle", "mold"]),
            c(52, "樱花灵", 65, ["cherry blossom", "petal", "sakura", "plum blossom", "falling flower", "floral"]),
            c(53, "竹节人", 60, ["bamboo", "reed", "sugarcane", "stalk", "joint", "bamboo grove", "stem"]),
            c(54, "果实灵", 59, ["fruit", "berry", "apple", "persimmon", "grape", "seed pod", "gourd", "melon"]),
            c(55, "云团", 61, ["cloud", "cotton", "wool", "foam", "cumulus", "white fluffy", "pillow", "marshmallow"]),
            c(56, "灯泡头", 58, ["light bulb", "lamp", "led", "neon", "streetlight", "spotlight", "torch"]),
            c(57, "钟表", 57, ["clock", "watch", "sundial", "timer", "hourglass", "calendar", "dial", "gauge"]),
            c(58, "信封", 57, ["envelope", "letter", "postcard", "stamp", "mailbox", "parcel", "message", "note"]),
            c(59, "相机", 58, ["camera", "lens", "telescope", "binoculars", "viewfinder", "film", "photograph"]),
            c(60, "留声机", 55, ["gramophone", "vinyl", "horn", "phonograph", "music box", "accordion"]),
            c(61, "算盘", 54, ["abacus", "calculator", "counting frame", "beads", "tally", "arithmetic"]),
            c(62, "陶瓷人", 55, ["porcelain", "ceramic", "pottery", "vase", "bowl", "blue and white", "glaze", "kiln"]),
            c(63, "线轴", 53, ["thread", "spool", "yarn", "weaving", "knitting", "fabric", "textile", "loom", "needle"]),
            c(64, "烛台", 54, ["candle", "candlestick", "wax", "flame", "wick", "chandelier", "taper"]),
            c(65, "纸伞", 56, ["umbrella", "parasol", "paper umbrella", "sunshade", "awning", "canopy"]),
            c(66, "镜像", 62, ["prism", "kaleidoscope", "crystal", "glass surface", "refraction", "spectrum"]),
            c(67, "残缺", 63, ["broken", "cracked", "torn", "missing", "fragment", "incomplete", "damaged", "glitch"]),
            c(68, "重影", 64, ["blur", "overlap", "transparent", "layered", "superimpose", "ghost image"]),
            c(69, "蛋形", 50, ["egg", "cocoon", "pod", "capsule", "nest", "seed", "embryo", "bud"]),
            c(70, "空", 45, ["empty", "void", "outline", "wireframe", "minimal", "transparent object"]),
            c(71, "锦鲤精", 62, ["koi", "carp", "goldfish", "ornamental fish", "colorful fish", "pond fish", "scale"]),
            c(72, "白鹤", 60, ["crane", "heron", "egret", "white bird", "long neck bird", "stork", "wading bird"]),
            c(73, "乌鸦", 61, ["crow", "raven", "jackdaw", "black bird", "corvid", "magpie"]),
            c(74, "蟾蜍", 63, ["toad", "bullfrog", "bumpy", "warty", "large frog", "horned frog"]),
            c(75, "白兔", 59, ["white rabbit", "albino rabbit", "red eye", "moon rabbit", "jade rabbit"]),
            c(76, "石灯", 64, ["stone lantern", "toro", "garden lamp", "shrine light"]),
            c(77, "山猪", 65, ["boar", "wild pig", "tusk", "bristle", "warthog", "feral pig"]),
            c(78, "瓦片人", 56, ["roof tile", "rooftop", "eaves", "shingle", "roof"]),
            c(79, "雉鸡", 57, ["pheasant", "peacock", "long tail feather", "colorful plumage", "tail feather", "bird of paradise"]),
            c(80, "河蟹", 58, ["river crab", "freshwater crab", "large claw", "mud crab", "hairy crab"]),
            c(81, "饭团", 55, ["rice ball", "onigiri", "rice", "white food"]),
            c(82, "松鼠", 54, ["squirrel", "chipmunk", "bushy tail", "acorn", "nut", "fluffy tail"]),
            c(83, "蜻蜓", 53, ["dragonfly", "damselfly", "four wings", "compound eye", "hovering insect"]),
            c(84, "蝉", 55, ["cicada", "locust", "summer insect", "tree insect", "buzzing", "shell"]),
            c(85, "螳螂", 52, ["mantis", "praying mantis", "sickle arm", "triangular head", "predatory insect"]),
            c(86, "白鹭", 58, ["egret", "little egret", "white heron", "marsh bird", "fishing bird", "plume"]),
            c(87, "牡丹精", 60, ["peony", "tree peony", "large flower", "layered petal", "chinese flower", "bloom"]),
            c(88, "梅花精", 56, ["plum blossom", "ume", "winter flower", "five petal", "plum tree", "early spring flower"]),
            c(89, "荷花童", 57, ["lotus", "water lily", "lily pad", "lotus pod", "lotus root", "pond flower", "pink water flower"]),
            c(90, "芭蕉精", 58, ["banana leaf", "plantain", "large tropical leaf", "banana tree", "palm leaf", "broad leaf"]),
            c(91, "布偶", 56, ["doll", "stuffed animal", "plush", "toy", "puppet"]),
            c(92, "茶树精", 54, ["tea tree", "tea plant", "tea leaf", "camellia sinensis", "young tea shoot", "fresh tea leaf"]),
            c(93, "竹笋精", 53, ["bamboo shoot", "spring shoot", "layered husk", "young bamboo", "sprout", "shoot"]),
            c(94, "枯木", 53, ["dead tree", "bare branch", "withered tree", "dry branch", "gnarled tree", "fallen tree"]),
            c(95, "莲花童", 54, ["lotus flower", "pink petal", "water bloom", "floating flower", "buddhist flower"]),
            c(96, "铃铛", 55, ["bell", "chime", "jingle", "wind bell", "furin"]),
            c(97, "太鼓", 56, ["drum", "taiko", "percussion", "tambourine", "bongo"]),
            c(98, "菊花精", 54, ["chrysanthemum", "autumn flower", "daisy", "radial petal", "sunflower pattern", "mum"]),
            c(99, "玫瑰骑士", 54, ["rose", "red flower", "thorn", "rosebud", "rose petal", "briar"]),
            c(100, "毒蘑菇精", 55, ["red mushroom", "toadstool", "white spot", "amanita", "fly agaric", "poisonous mushroom"]),
            c(101, "毛笔", 55, ["brush", "calligraphy brush", "ink brush", "writing brush"]),
            c(102, "印章", 55, ["stamp", "seal", "chop", "hanko", "red stamp"]),
            c(103, "常青藤", 54, ["ivy", "evergreen", "climbing plant vine", "wall plant", "creeping vine", "english ivy"]),
            c(104, "卷轴", 54, ["scroll", "roll", "parchment roll", "bamboo scroll"]),
            c(105, "向日葵", 52, ["sunflower", "large yellow flower", "seed head", "helianthus", "sun face flower"]),
            c(106, "蓟花精", 52, ["thistle", "purple spiky flower", "thorny flower", "scotland flower", "globe thistle", "spear thistle"]),
            c(107, "药瓶", 52, ["bottle", "vial", "potion", "medicine", "flask", "jar"]),
            c(108, "网切", 53, ["spider web", "cobweb", "large spider", "arachnid", "web pattern", "silk thread"]),
            c(109, "轮入道", 52, ["wheel", "spinning", "fire wheel", "rotating", "cartwheel", "wagon wheel", "mill wheel"]),
            c(110, "眼球", 51, ["eye", "eyeball", "iris", "pupil", "lens", "stare"]),
            c(111, "舟", 52, ["boat", "canoe", "wooden boat", "vessel", "sampan"]),
            c(112, "濡女", 52, ["long hair", "river", "female figure", "water snake", "serpent woman", "wet hair"]),
            c(113, "锚", 53, ["anchor", "chain", "maritime", "harbor", "dock"]),
            c(114, "雪坊主", 52, ["snowball", "large round snow", "rolling snow", "snow pile", "snow mound", "deep snow"]),
            c(115, "山童", 50, ["monkey", "primate", "wild child", "branch", "forest creature", "small ape", "gibbon"]),
            c(116, "达摩", 58, ["daruma", "round doll", "tumbler", "wishing doll", "bodhidharma", "red round figure", "no limbs doll"]),
            c(117, "月相", 58, ["moon", "crescent", "lunar", "moonlight", "full moon"]),
            c(118, "骨伞", 57, ["broken umbrella", "torn umbrella", "old parasol", "damaged umbrella", "skeleton umbrella", "worn parasol"]),
            c(119, "茶壶精", 57, ["teapot", "kettle", "round pot", "spout", "iron kettle", "clay pot", "brewing vessel"]),
            c(120, "风铃", 55, ["wind chime", "glass bell", "hanging bell", "summer bell", "furin", "chime tube", "glass tube"])
        ]
    }

    nonisolated private static func c(_ id: Int, _ name: String, _ weight: Int, _ words: [String]) -> FormCluster {
        FormCluster(
            formId: id,
            name: name,
            keywords: Set(words.map(normalize)),
            priorityWeight: weight,
            personality: personality(for: id)
        )
    }
}
