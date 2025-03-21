import 'package:internal_core/internal_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internal_network/options.dart';
 

internalSetup() {
  AppSetup.initialized(
    value: AppSetup(
      env: AppEnv.preprod,
      appColors: null,
      appPrefs: null,
      appTextStyleWrap: AppTextStyleWrap(
        fontWrap: (textStyle) => GoogleFonts.inter(textStyle: textStyle),
      ),
      networkOptions: PNetworkOptionsImpl(
        loggingEnable: true,
        baseUrl: 'https://familyworld.xyz/api/',
        baseUrlAsset: 'https://familyworld.xyz/',
        responsePrefixData: 'data',
        // errorInterceptor: (e) {
        //   print(e);
        // },
      ),
    ),
  );
}
