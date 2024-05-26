import 'package:strava_client/strava_client.dart';

class StravaAuthentication {
  final StravaClient stravaClient;
  StravaAuthentication(this.stravaClient);

  Future<TokenResponse> Authentication(
      List<AuthenticationScope> scopes, String redirectUrl) {
    return stravaClient.authentication.authenticate(
        scopes: scopes,
        redirectUrl: redirectUrl,
        forceShowingApproval: false,
        callbackUrlScheme: "com.example.flutter",
        preferEphemeral: true);
  }

  Future<void> Deauthorize() {
    return stravaClient.authentication.deAuthorize();
  }
}
