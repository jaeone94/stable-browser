import Foundation
import UIKit

class Img2ImgGenerationContext: StableGenerationContext {
    init(mode: Img2ImgMode,
          initImages: [UIImage],
          mask: UIImage? = nil,
          maskBlur: Int = 30,
          inpaintingFill: Int = 0,
          inpaintFullRes: Bool = true,
          inpaintFullResPadding: Int = 1,
          inpaintingMaskInvert: Int = 1,
          resizeMode: Int = 0,
          denoisingStrength: Double = 0.7,
          prompt: String,
          negativePrompt: String = "",
          styles: [String] = [],
          seed: Int = -1,
          subseed: Int = -1,
          subseedStrength: Double = 0,
          seedResizeFromH: Int = 0,
          seedResizeFromW: Int = 0,
          samplerName: String? = nil,
          batchSize: Int = 1,
          nIter: Int = 1,
          steps: Int? = nil,
          cfgScale: Double = 7,
          width: Int = 512,
          height: Int = 512,
          restoreFaces: Bool = false,
          tiling: Bool = false,
          doNotSaveSamples: Bool = false,
          doNotSaveGrid: Bool = false,
          eta: Double = 1,
          sChurn: Double = 0,
          sTmax: Double = 0,
          sTmin: Double = 0,
          sNoise: Double = 1,
          overrideSettings: [String: Any] = [:],
          overrideSettingsRestoreAfterwards: Bool = true,
          includeInitImages: Bool = true,
          scriptArgs: [Any] = [],
          sendImages: Bool = true,
          saveImages: Bool = false,
          alwaysonScripts: [String: [String: Any]] = [:]) 
    {
        super.init()
        
        let initImagesBase64 = initImages.map { ImageUtils.rawB64img($0) }
        let maskBase64 = mask.map { ImageUtils.rawB64img($0) }
        
        var payload: [String: Any] = [
            "init_images": initImagesBase64,
            "denoising_strength": denoisingStrength,
            "prompt": prompt,
            "negative_prompt": negativePrompt,
            "styles": styles,
            "seed": seed,
            "subseed": subseed,
            "subseed_strength": subseedStrength,
            "seed_resize_from_h": seedResizeFromH,
            "seed_resize_from_w": seedResizeFromW,
            "sampler_name": samplerName ?? "Euler a",
            "batch_size": batchSize,
            "n_iter": nIter,
            "steps": steps ?? 20,
            "cfg_scale": cfgScale,
            "width": width,
            "height": height,
            "restore_faces": restoreFaces,
            "tiling": tiling,
            "do_not_save_samples": doNotSaveSamples,
            "do_not_save_grid": doNotSaveGrid,
            "eta": eta,
            "s_churn": sChurn,
            "s_tmax": sTmax,
            "s_tmin": sTmin,
            "s_noise": sNoise,
            "override_settings": overrideSettings,
            "override_settings_restore_afterwards": overrideSettingsRestoreAfterwards,
            "include_init_images": includeInitImages,
            "script_args": scriptArgs,
            "send_images": sendImages,
            "save_images": saveImages,
            "alwayson_scripts": alwaysonScripts
        ]
        
        if mode == .inpaint {
            payload["mask"] = maskBase64 ?? "";
            payload["mask_blur"] = maskBlur;
            payload["inpainting_fill"] = inpaintingFill;
            payload["inpaint_full_res"] = inpaintFullRes;
            payload["inpaint_full_res_padding"] = inpaintFullResPadding;
            payload["inpainting_mask_invert"] = inpaintingMaskInvert;
            payload["resize_mode"] = resizeMode;
        }
        
        self.type = .img2img
        self.payload = payload
    }
}
