import Foundation
import UIKit

class Txt2ImgGenerationContext: StableGenerationContext {
    init(enable_hr: Bool = false,
         denoising_strength: Double = 0.7,
         firstphase_width: Int = 0,
         firstphase_height: Int = 0,
         hr_scale: Double = 2.0,
         hr_upscaler: HiResUpscaler = .latent,
         hr_second_pass_steps: Int = 0,
         hr_resize_x: Int = 0,
         hr_resize_y: Int = 0,
         prompt: String = "",
         styles: [String] = [],
         seed: Int = -1,
         subseed: Int = -1,
         subseed_strength: Double = 0.0,
         seed_resize_from_h: Int = 0,
         seed_resize_from_w: Int = 0,
         sampler_name: String? = nil,
         batch_size: Int = 1,
         n_iter: Int = 1,
         steps: Int? = nil,
         cfg_scale: Double = 7.0,
         width: Int = 512,
         height: Int = 512,
         restore_faces: Bool = false,
         tiling: Bool = false,
         do_not_save_samples: Bool = false,
         do_not_save_grid: Bool = false,
         negative_prompt: String = "",
         eta: Double = 1.0,
         s_churn: Double = 0.0,
         s_tmax: Double = 0.0,
         s_tmin: Double = 0.0,
         s_noise: Double = 1.0,
         override_settings: [String: Any] = [:],
         override_settings_restore_afterwards: Bool = true,
         script_args: [Any]? = nil,
         script_name: String? = nil,
         send_images: Bool = true,
         save_images: Bool = false,
         alwayson_scripts: [String: Any] = [:],
         // controlnet_units: [ControlNetUnit] = [],
         // adetailer: [ADetailer] = [],
         // roop: Roop? = nil,
         // reactor: ReActor? = nil,
         // sag: Sag? = nil,
         sampler_index: String? = nil,
         use_deprecated_controlnet: Bool = false,
         use_async: Bool = false)
    {
        super.init()
        
        let samplerName = sampler_name ?? "Euler a"
        let stepsCount = steps ?? 20
        let scriptArgs = script_args ?? []
        
        let payload: [String: Any] = [
            "enable_hr": enable_hr,
            "hr_scale": hr_scale,
            "hr_upscaler": hr_upscaler.rawValue,
            "hr_second_pass_steps": hr_second_pass_steps,
            "hr_resize_x": hr_resize_x,
            "hr_resize_y": hr_resize_y,
            "denoising_strength": denoising_strength,
            "firstphase_width": firstphase_width,
            "firstphase_height": firstphase_height,
            "prompt": prompt,
            "styles": styles,
            "seed": seed,
            "subseed": subseed,
            "subseed_strength": subseed_strength,
            "seed_resize_from_h": seed_resize_from_h,
            "seed_resize_from_w": seed_resize_from_w,
            "batch_size": batch_size,
            "n_iter": n_iter,
            "steps": stepsCount,
            "cfg_scale": cfg_scale,
            "width": width,
            "height": height,
            "restore_faces": restore_faces,
            "tiling": tiling,
            "do_not_save_samples": do_not_save_samples,
            "do_not_save_grid": do_not_save_grid,
            "negative_prompt": negative_prompt,
            "eta": eta,
            "s_churn": s_churn,
            "s_tmax": s_tmax,
            "s_tmin": s_tmin,
            "s_noise": s_noise,
            "override_settings": override_settings,
            "override_settings_restore_afterwards": override_settings_restore_afterwards,
            "sampler_name": samplerName,
            "sampler_index": sampler_index ?? samplerName,
            "script_name": script_name ?? "",
            "script_args": scriptArgs,
            "send_images": send_images,
            "save_images": save_images,
            "alwayson_scripts": alwayson_scripts,
        ]
        
        // if use_deprecated_controlnet, !controlnet_units.isEmpty {
        //     payload["controlnet_units"] = controlnet_units.map { $0.toDictionary() }
        //     return await sendRequest(path: "controlnet/txt2img", payload: payload)
        // }
 
        // if !adetailer.isEmpty {
        //     var ads = [true]
        //     ads.append(contentsOf: adetailer.map { $0.toDictionary() })
        //     payload["alwayson_scripts"]["ADetailer"] = ["args": ads]
        // } else if hasADetailer {
        //     payload["alwayson_scripts"]["ADetailer"] = ["args": [false]]
        // }
        //
        // if let roop = roop {
        //     payload["alwayson_scripts"]["roop"] = ["args": roop.toDictionary()]
        // }
        //
        // if let reactor = reactor {
        //     payload["alwayson_scripts"]["reactor"] = ["args": reactor.toDictionary()]
        // }
 
        // if let sag = sag {
        //     payload["alwayson_scripts"]["Self Attention Guidance"] = ["args": sag.toDictionary()]
        // }
 
        // if !controlnet_units.isEmpty {
        //     payload["alwayson_scripts"]["ControlNet"] = ["args": controlnet_units.map { $0.toDictionary() }]
        // } else if hasControlNet {
        //     payload["alwayson_scripts"]["ControlNet"] = ["args": []]
        // }
        
        self.type = .txt2img
        self.payload = payload
    }
}
