struct OverrideSettings: Decodable {
    let sd_model_checkpoint: String
    let CLIP_stop_at_last_layers: Int
    
    enum CodingKeys: CodingKey {
        case sd_model_checkpoint
        case CLIP_stop_at_last_layers
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sd_model_checkpoint = try container.decode(String.self, forKey: .sd_model_checkpoint)
        self.CLIP_stop_at_last_layers = try container.decode(Int.self, forKey: .CLIP_stop_at_last_layers)
    }
}
