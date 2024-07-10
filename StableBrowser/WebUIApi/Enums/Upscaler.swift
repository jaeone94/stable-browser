enum Upscaler: String {
    case none = "None"
    case lanczos = "Lanczos"
    case nearest = "Nearest"
    case ldsr = "LDSR"
    case bsrgan = "BSRGAN"
    case esrgan4x = "R-ESRGAN 4x+"
    case rEsrganGeneral4xV3 = "R-ESRGAN General 4xV3"
    case scunetGAN = "ScuNET GAN"
    case scunetPSNR = "ScuNET PSNR"
    case swinIR4x = "SwinIR 4x"
}
